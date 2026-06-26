#!/bin/bash
# ============================================================
# SARA3 - batch_test_8p.sh (wrapper de compatibilidad)
# ------------------------------------------------------------
# La lógica real del flujo batch vive en RunTest.sh (fuente única).
# Este wrapper existe para no romper las referencias en:
#   - docker-compose.yml
#   - docker-helper.sh
#   - cron_wrapper.sh
#   - .github/workflows/docker-batch-tests.yml
#
# El número de runners se controla con la variable RUNNERS (default 8):
#   RUNNERS=12 ./batch_test_8p.sh
# ============================================================
exec "$(dirname "$0")/RunTest.sh" "$@"
