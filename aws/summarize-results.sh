#!/usr/bin/env bash
# Consolida los logs descargados en un CSV resumen.
# Uso: summarize-results.sh <RESULTS_DIR> [OUT_CSV]
set -euo pipefail
DIR="${1:?Uso: summarize-results.sh <RESULTS_DIR> [OUT_CSV]}"
OUT="${2:-${DIR}/summary.csv}"

echo "instance,tests_completed,tests_failed,timeouts" > "$OUT"
for d in "$DIR"/instance-*/; do
  [ -d "$d" ] || continue
  inst="$(basename "$d")"
  log="$(find "$d" -name '*.log' | head -1 || true)"
  if [ -z "$log" ]; then
    echo "${inst},NA,NA,NA" >> "$OUT"
    continue
  fi
  line="$(grep -oE '[0-9]+ tests completed, [0-9]+ failed' "$log" | tail -1 || true)"
  completed="$(printf '%s' "$line" | grep -oE '^[0-9]+' || echo 0)"
  failed="$(printf '%s' "$line" | grep -oE '[0-9]+ failed' | grep -oE '^[0-9]+' || echo 0)"
  timeouts="$(grep -c 'TimeoutException' "$log" || true)"
  echo "${inst},${completed:-0},${failed:-0},${timeouts:-0}" >> "$OUT"
done
cat "$OUT"
