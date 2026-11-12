# Release signing keys

## Current production key

`dshd-linux-release-signing.asc` is the public half of the current release key.

- Fingerprint: `2D4C2CFD4F1C3B5F8AF0DA481C9A912742C70369`
- UID: `DSHD for Linux Release Signing <release@dshd-linux.invalid>`
- Algorithm: Ed25519 (sign)
- Created: 2026-11-12; expires: 2028-11-11
- Private key: offline/passphrase-protected, not in this repository

Import and verify:

```bash
gpg --import keys/dshd-linux-release-signing.asc
gpg --fingerprint 2D4C2CFD4F1C3B5F8AF0DA481C9A912742C70369
scripts/verify-artifacts.sh
```

## Historical reference key

`deepseek-harness-release-signing.asc` is the passphrase-less reference key used
for `v0.2.2-rc.1` only. Keep it to verify that older release; do not use it for
new releases.

- Fingerprint: `0E6023DF4DB8C68AA2202EF876CE5675AFF067FF`
- UID: `DeepSeek Harness Linux Release Signing (release artifacts only) <linux-release@deepseek-harness.invalid>`

Only public keys belong in git. Private keys and revocation certificates must be
backed up offline; see [../docs/release-signing.md](../docs/release-signing.md).
