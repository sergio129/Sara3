#!/usr/bin/env bash
# Genera los argumentos --tests de Gradle para un shard dado.
# Uso: shard-tests.sh <SHARD> [PER]
#   SHARD: 0-based; el shard s cubre las clases [s*PER+1 .. s*PER+PER]
#   PER: clases por shard (default 10). Se limita a la clase 50.
set -euo pipefail

SHARD="${1:?Uso: shard-tests.sh <SHARD> [PER]}"
PER="${2:-10}"
PKG="com.sara.automation.runners"
MAX=50

start=$(( SHARD * PER + 1 ))
end=$(( SHARD * PER + PER ))

args=""
for n in $(seq "$start" "$end"); do
  [ "$n" -gt "$MAX" ] && break
  printf -v cls "CasesRunner%02d" "$n"
  args+=" --tests \"${PKG}.${cls}\""
done
echo "${args# }"
