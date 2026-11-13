#!/usr/bin/env bash
# Convert legacy binary Office files (.doc/.xls/.ppt) through the packaged
# LibreOfficeKit WASM CLI and assert that each output is a PDF.
#
# Usage:
#   scripts/e2e-legacy-office.sh <fixtures-dir> [output-dir]
#
# On a packaged install the defaults are:
#   APP_DIR="/opt/deepseek-harness"
#   NODE="$APP_DIR/resources/runtime/primary-runtime/dependencies/node/bin/node"
# Override APP_DIR/NODE/CLI for a development tree.
set -euo pipefail

FIXTURES="${1:?usage: $0 <fixtures-dir> [output-dir]}"
OUT="${2:-$(mktemp -d)}"
APP_DIR="${APP_DIR:-/opt/deepseek-harness}"
NODE="${NODE:-$APP_DIR/resources/runtime/primary-runtime/dependencies/node/bin/node}"
CLI="${CLI:-$APP_DIR/resources/app.asar.unpacked/dsh/node_modules/@deepseek-ai/libreoffice-kit/lib/cli.js}"

[ -x "$NODE" ] || { echo "node not found: $NODE" >&2; exit 2; }
[ -f "$CLI" ] || { echo "converter not found: $CLI" >&2; exit 2; }
mkdir -p "$OUT"

failed=0
for ext in doc xls ppt; do
  input="$(find "$FIXTURES" -maxdepth 1 -type f -iname "*.$ext" -print -quit)"
  if [ -z "$input" ]; then
    echo "SKIP .$ext: no fixture in $FIXTURES"
    continue
  fi
  name="$(basename "${input%.*}")"
  pdf="$OUT/$name.pdf"
  echo "== .$ext $input"
  rm -f "$pdf"
  if ! "$NODE" "$CLI" convert --input "$input" --output "$pdf"; then
    echo "FAIL .$ext conversion" >&2
    failed=1
    continue
  fi
  if [ "$(head -c 5 "$pdf")" != "%PDF-" ]; then
    echo "FAIL .$ext output is not a PDF: $pdf" >&2
    failed=1
    continue
  fi
  echo "OK .$ext -> $pdf ($(wc -c <"$pdf") bytes)"
done

[ "$failed" -eq 0 ] || exit 1
echo "legacy Office conversions: PASS"
