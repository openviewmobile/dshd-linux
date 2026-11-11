# Release signing key

`deepseek-harness-release-signing.asc` is the public half of the release key.

- Fingerprint: `0E6023DF4DB8C68AA2202EF876CE5675AFF067FF`
- UID: `DeepSeek Harness Linux Release Signing (release artifacts only) <linux-release@deepseek-harness.invalid>`
- Created: 2026-11-09; expires: 2028-11-08

Import and verify:

```bash
gpg --import keys/deepseek-harness-release-signing.asc
gpg --fingerprint 0E6023DF4DB8C68AA2202EF876CE5675AFF067FF
scripts/verify-artifacts.sh
```

Only the public key belongs in git. The private key and revocation certificate
must be backed up offline; see [../docs/release-signing.md](../docs/release-signing.md).
