#!/usr/bin/env bash
# Consolida los logs descargados en un CSV resumen.
# Uso: summarize-results.sh <RESULTS_DIR> [OUT_CSV]
#
# Columnas:
#   instance          - id de la instancia
#   tests_completed   - "N tests completed" reportado por Gradle (vacío si BUILD SUCCESSFUL)
#   tests_failed      - "M failed" reportado por Gradle/JUnit (fuente de verdad del resultado)
#   timeouts          - nº de TimeoutException en el log (timeouts de la app bajo carga)
#   nosession         - nº de NoSuchSessionException (FIRMA del crash de Chrome/renderer)
#   serenity_passed   - "Passed" del summary.txt de Serenity
#   serenity_notpass  - "Failed" + "Failed with errors" de Serenity
#   flag              - OK | FALSE_SUCCESS | NO_REPORT | NO_LOG
#
# FALSE_SUCCESS: Serenity reporta todo verde pero Gradle/JUnit acusa fallos, o
# hubo NoSuchSessionException (Chrome se cayó dejando pasos en estado nulo).
# Ver memoria 'serenity-falsos-success-crash-chrome': el verde de Serenity NO es
# confiable cuando Chrome crashea; manda el conteo de Gradle/JUnit.
set -euo pipefail
DIR="${1:?Uso: summarize-results.sh <RESULTS_DIR> [OUT_CSV]}"
OUT="${2:-${DIR}/summary.csv}"

echo "instance,tests_completed,tests_failed,timeouts,nosession,serenity_passed,serenity_notpass,flag" > "$OUT"
for d in "$DIR"/instance-*/; do
  [ -d "$d" ] || continue
  inst="$(basename "$d")"
  log="$(find "$d" -name '*.log' | head -1 || true)"
  if [ -z "$log" ]; then
    echo "${inst},NA,NA,NA,NA,NA,NA,NO_LOG" >> "$OUT"
    continue
  fi

  # --- Gradle / JUnit (fuente de verdad del resultado) ---
  line="$(grep -oE '[0-9]+ tests completed, [0-9]+ failed' "$log" | tail -1 || true)"
  completed="$(printf '%s' "$line" | grep -oE '^[0-9]+' || echo 0)"
  failed="$(printf '%s' "$line" | grep -oE '[0-9]+ failed' | grep -oE '^[0-9]+' || echo 0)"
  timeouts="$(grep -c 'TimeoutException' "$log" || true)"
  nosession="$(grep -c 'NoSuchSessionException' "$log" || true)"

  # --- Serenity (puede dar falsos SUCCESS si Chrome crashea) ---
  st="$(find "$d" -name summary.txt -path '*serenity*' | head -1 || true)"
  if [ -n "$st" ]; then
    spass="$(grep -E '^Passed:' "$st" | grep -oE '[0-9]+' | head -1 || echo 0)"
    sfail="$(grep -E '^Failed:' "$st" | grep -oE '[0-9]+' | head -1 || echo 0)"
    serr="$(grep -E 'Failed with errors' "$st" | grep -oE '[0-9]+' | head -1 || echo 0)"
    snotpass=$(( ${sfail:-0} + ${serr:-0} ))
  else
    spass="NA"; snotpass="NA"
  fi

  # --- Guardrail: detectar falso SUCCESS ---
  flag="OK"
  if [ -z "$st" ]; then
    flag="NO_REPORT"
  elif [ "${nosession:-0}" -gt 0 ]; then
    flag="FALSE_SUCCESS"
  elif [ "${failed:-0}" -gt 0 ] && [ "${snotpass:-0}" -eq 0 ]; then
    flag="FALSE_SUCCESS"
  fi

  echo "${inst},${completed:-0},${failed:-0},${timeouts:-0},${nosession:-0},${spass},${snotpass},${flag}" >> "$OUT"
done
cat "$OUT"

# Aviso final si alguna instancia tiene reporte Serenity poco confiable.
if grep -q ',FALSE_SUCCESS$' "$OUT"; then
  echo ""
  echo "⚠️  ATENCIÓN: hay instancias con FALSE_SUCCESS (Chrome se cayó y/o Serenity"
  echo "    reporta verde pese a fallos de Gradle). NO confíes en el reporte Serenity"
  echo "    de esas instancias; el resultado real es el de Gradle/JUnit (tests_failed)."
fi
