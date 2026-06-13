#!/bin/bash
# ============================================================
# SARA3 - BATCH TEST RUNNER (8 paralelos por defecto)
# ------------------------------------------------------------
# Ejecuta TODOS los runners (CasesRunner01-50) con N forks en
# paralelo. Cada fork = 1 navegador Chrome headless.
#
# Uso:  batch_test_8p.sh [num_forks]      (default: 8)
#
# NOTA: El entrypoint (docker-entrypoint.sh) ya inicia Xvfb
#       antes de invocar este script, por lo que aquí solo se
#       lanza Gradle.
# ============================================================
set -uo pipefail

FORKS="${1:-8}"

echo "╔════════════════════════════════════════════════════════╗"
echo "║  🚀 SARA3 BATCH TEST  |  maxParallelForks=${FORKS}"
echo "╚════════════════════════════════════════════════════════╝"

cd /app || { echo "❌ No existe /app"; exit 1; }

# maxParallelForks se lee como PROJECT property en build.gradle (-P, no -D)
./gradlew test \
    -PmaxParallelForks="${FORKS}" \
    --continue \
    --no-daemon

EXIT_CODE=$?

echo "╔════════════════════════════════════════════════════════╗"
echo "║  ✅ BATCH FINALIZADO  |  exit=${EXIT_CODE}"
echo "║  📊 Reporte: target/site/serenity/index.html"
echo "╚════════════════════════════════════════════════════════╝"

exit $EXIT_CODE
