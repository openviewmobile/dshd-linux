#!/usr/bin/env bash
# Sign the x64 checksum file for distribution. Requires a real release key:
#   DSHD_GPG_KEY=<fingerprint> scripts/sign-artifacts.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${DIR:-$ROOT/dist/linux-x64}"
KEY="${DSHD_GPG_KEY:?set DSHD_GPG_KEY to the release signing fingerprint}"
[ -f "$DIR/SHA256SUMS" ] || { echo "missing $DIR/SHA256SUMS" >&2; exit 1; }
gpg --batch --yes --armor --detach-sign --local-user "$KEY" \
  -o "$DIR/SHA256SUMS.asc" "$DIR/SHA256SUMS"
gpg --verify "$DIR/SHA256SUMS.asc" "$DIR/SHA256SUMS"
echo "signed: $DIR/SHA256SUMS.asc"
