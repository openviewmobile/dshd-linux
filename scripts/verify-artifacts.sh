#!/usr/bin/env bash
# Verify checksums and, when present, the detached GPG signature.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${DIR:-$ROOT/dist/linux-x64}"
( cd "$DIR" && shasum -a 256 -c SHA256SUMS )
if [ -f "$DIR/SHA256SUMS.asc" ]; then
  gpg --verify "$DIR/SHA256SUMS.asc" "$DIR/SHA256SUMS"
fi
