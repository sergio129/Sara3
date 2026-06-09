#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
SUM="$here/../summarize-results.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/instance-0" "$tmp/instance-1"
cat > "$tmp/instance-0/run.log" <<'LOG'
> Task :test
50 tests completed, 4 failed
org.openqa.selenium.TimeoutException: ...
org.openqa.selenium.TimeoutException: ...
LOG
cat > "$tmp/instance-1/run.log" <<'LOG'
> Task :test
10 tests completed, 0 failed
LOG

out="$tmp/summary.csv"
bash "$SUM" "$tmp" "$out" >/dev/null

grep -q "^instance-0,50,4,2$" "$out" || { echo "FAIL: fila instance-0 incorrecta"; cat "$out"; exit 1; }
grep -q "^instance-1,10,0,0$" "$out" || { echo "FAIL: fila instance-1 incorrecta"; cat "$out"; exit 1; }
echo "OK summarize-results"
