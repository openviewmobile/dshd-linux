#!/usr/bin/env bash
# Sign release artifacts with a detached, armored GPG signature.
#
#   DSHD_GPG_KEY=<fingerprint> scripts/sign-artifacts.sh
#   DSHD_GPG_KEY=<fingerprint> DIR=dist/linux-x64 scripts/sign-artifacts.sh
#
# Every regular file in each directory (except existing .asc files) is signed,
# including the regenerated SHA256SUMS.  The private key must never be committed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEY="${DSHD_GPG_KEY:?set DSHD_GPG_KEY to the release signing fingerprint}"

if [ -n "${DIR:-}" ]; then
  DIRS=("$DIR")
else
  DIRS=("$ROOT/dist/linux-x64" "$ROOT/dist/linux-arm64" "$ROOT/dist/arch" "$ROOT/dist/snap" "$ROOT/dist/obs")
fi

command -v gpg >/dev/null || { echo "gpg is required" >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then
  SHA256=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then
  SHA256=(shasum -a 256)
else
  echo "sha256sum or shasum is required" >&2
  exit 1
fi
gpg --list-secret-keys --with-colons "$KEY" >/dev/null 2>&1 || {
  echo "secret key not found: $KEY" >&2
  exit 1
}

for dir in "${DIRS[@]}"; do
  [ -d "$dir" ] || { echo "skipping missing $dir" >&2; continue; }
  (
    cd "$dir"
    : > SHA256SUMS
    for f in *; do
      [ -f "$f" ] || continue
      case "$f" in
        *.asc|SHA256SUMS) continue ;;
      esac
      "${SHA256[@]}" "$f" >> SHA256SUMS
    done
    [ -s SHA256SUMS ] || { echo "no artifacts in $dir" >&2; exit 1; }
    for f in *; do
      [ -f "$f" ] || continue
      case "$f" in
        *.asc) continue ;;
      esac
      gpg --batch --yes --armor --detach-sign --local-user "$KEY" "$f"
    done
    gpg --verify SHA256SUMS.asc SHA256SUMS >/dev/null
    echo "signed: $dir"
  )
done
