#!/usr/bin/env bash
# Verify checksums and detached GPG signatures for release artifacts.
#
#   scripts/verify-artifacts.sh
#   DIR=dist/linux-x64 scripts/verify-artifacts.sh
#
# Import the release public key first, for example:
#   gpg --import keys/dshd-linux-release-signing.asc
#   gpg --import keys/deepseek-harness-release-signing.asc  # v0.2.2-rc.1 only
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if command -v sha256sum >/dev/null 2>&1; then
  SHA_CHECK=(sha256sum -c)
elif command -v shasum >/dev/null 2>&1; then
  SHA_CHECK=(shasum -a 256 -c)
else
  echo "sha256sum or shasum is required" >&2
  exit 1
fi

if [ -n "${DIR:-}" ]; then
  DIRS=("$DIR")
else
  DIRS=("$ROOT/dist/linux-x64" "$ROOT/dist/linux-arm64" "$ROOT/dist/arch" "$ROOT/dist/snap" "$ROOT/dist/obs")
fi

for dir in "${DIRS[@]}"; do
  [ -d "$dir" ] || { echo "skipping missing $dir" >&2; continue; }
  echo "== $dir"
  (
    cd "$dir"
    "${SHA_CHECK[@]}" SHA256SUMS
    for sig in *.asc; do
      [ -f "$sig" ] || continue
      file="${sig%.asc}"
      gpg --verify "$sig" "$file"
    done
  )
done
