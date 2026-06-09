#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
ST="$here/../shard-tests.sh"

out0=$("$ST" 0 10)
echo "$out0" | grep -q 'CasesRunner01"' || { echo "FAIL: shard0 sin 01"; exit 1; }
echo "$out0" | grep -q 'CasesRunner10"' || { echo "FAIL: shard0 sin 10"; exit 1; }
if echo "$out0" | grep -q 'CasesRunner11"'; then echo "FAIL: shard0 incluye 11"; exit 1; fi

out4=$("$ST" 4 10)
echo "$out4" | grep -q 'CasesRunner41"' || { echo "FAIL: shard4 sin 41"; exit 1; }
echo "$out4" | grep -q 'CasesRunner50"' || { echo "FAIL: shard4 sin 50"; exit 1; }

out_small=$("$ST" 1 2)
echo "$out_small" | grep -q 'CasesRunner03"' || { echo "FAIL: shard1/PER2 sin 03"; exit 1; }
echo "$out_small" | grep -q 'CasesRunner04"' || { echo "FAIL: shard1/PER2 sin 04"; exit 1; }

out_hi=$("$ST" 9 10)   # 91..100 -> todo >50 -> vacío
[ -z "$out_hi" ] || { echo "FAIL: shard9 deberia ser vacio"; exit 1; }

echo "OK shard-tests"
