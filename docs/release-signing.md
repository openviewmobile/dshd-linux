# Release signing

Every published artifact has a detached, armored GPG signature (`.asc`), and
each artifact directory has a signed `SHA256SUMS`. This gives users a chain from
the published public key to the bytes they install.

## Release keys

### Current key (next release onward)

| Field | Value |
|---|---|
| UID | `DSHD for Linux Release Signing <release@dshd-linux.invalid>` |
| Fingerprint | `2D4C2CFD4F1C3B5F8AF0DA481C9A912742C70369` |
| Key ID | `1C9A912742C70369` |
| Type | Ed25519 (sign) |
| Created | 2026-11-12 |
| Expires | 2028-11-11 |
| Public key | [`keys/dshd-linux-release-signing.asc`](../keys/dshd-linux-release-signing.asc) |
| Private key | offline, passphrase-protected, not in this repository |

### Historical key (`v0.2.2-rc.1.1` and earlier)

| Field | Value |
|---|---|
| UID | `DeepSeek Harness Linux Release Signing (release artifacts only) <linux-release@deepseek-harness.invalid>` |
| Fingerprint | `0E6023DF4DB8C68AA2202EF876CE5675AFF067FF` |
| Public key | [`keys/deepseek-harness-release-signing.asc`](../keys/deepseek-harness-release-signing.asc) |

The historical key was the passphrase-less reference key used before the
production key rotation. Keep it for the existing earlier releases; do not
use it for new releases.

The `.invalid` domain is intentional: this is a project release identity, not a
mailbox. Report security issues through the private advisory flow in
[SECURITY.md](../SECURITY.md).

## What is signed

For each directory:

```text
dist/linux-x64/    AppImage, deb, rpm, flatpak, SHA256SUMS + .asc for each
dist/linux-arm64/  AppImage, deb, rpm, flatpak, SHA256SUMS + .asc for each
dist/arch/         .pkg.tar.zst, SHA256SUMS + .asc
dist/snap/         .snap, SHA256SUMS + .asc
dist/obs/          .rpm, SHA256SUMS + .asc
```

The historical `unsigned` suffix in filenames means “no platform code-signing
certificate”; it does **not** mean the detached signature is missing. GPG
signatures are not a substitute for a platform certificate, and they are not
automatically trusted by package managers.

## Verify a download

```bash
# 1. Import the key for the release you downloaded.
# New releases:
gpg --import keys/dshd-linux-release-signing.asc
gpg --fingerprint 2D4C2CFD4F1C3B5F8AF0DA481C9A912742C70369
# Existing v0.2.2-rc.1 only:
# gpg --import keys/deepseek-harness-release-signing.asc
# gpg --fingerprint 0E6023DF4DB8C68AA2202EF876CE5675AFF067FF

# 2. Verify the checksum file and the artifact you downloaded.
gpg --verify SHA256SUMS.asc SHA256SUMS
sha256sum -c SHA256SUMS

# 3. Verify the artifact's own signature (optional but recommended).
gpg --verify deepseek-harness-0.2.2-rc.1-linux-x86_64-unsigned.AppImage.asc \
            deepseek-harness-0.2.2-rc.1-linux-x86_64-unsigned.AppImage
```

A good signature means the file was signed by the holder of the release key and
has not changed. It does not prove that the key belongs to a particular person;
compare the fingerprint through an independent channel before trusting it.

## Re-sign a local build

```bash
export DSHD_GPG_KEY=0E6023DF4DB8C68AA2202EF876CE5675AFF067FF
scripts/sign-artifacts.sh
scripts/verify-artifacts.sh
```

`sign-artifacts.sh` regenerates `SHA256SUMS` from the files actually present,
then signs every regular file (including `SHA256SUMS`). It refuses to run if the
secret key is not in the local keyring. A single directory can be signed with
`DIR=dist/linux-x64 scripts/sign-artifacts.sh`.

## Private key handling

- The private key is **not** in this repository, `dist/`, or any evidence file.
- The reference key was generated for this release on the release host and has
  no passphrase so that the signing step is reproducible in this environment.
  Before a public production release, replace it with an offline,
  passphrase-protected key (or an HSM-backed key), publish the new fingerprint,
  and re-sign the artifacts.
- Back up the secret key and revocation certificate offline. Losing the key
  prevents updates to an existing release; leaking it requires a revocation and
  a new key. Example (never commit the result):

  ```bash
  gpg --armor --export-secret-keys 0E6023DF4DB8C68AA2202EF876CE5675AFF067FF \
    | gpg --symmetric --cipher-algo AES256 -o release-secret.asc.gpg
  ```

  Store the passphrase and the encrypted file separately. The revocation
  certificate is in `~/.gnupg/openpgp-revocs.d/<fingerprint>.rev`.
- Do not add the private key to GitHub Actions as a long-lived secret unless the
  workflow is protected by a reviewed environment and a passphrase.
- Rotate the key before expiry (2028-11-08) and publish the new fingerprint in
  the release notes.

## Release upload list

Upload the artifact and its `.asc`, plus `SHA256SUMS` and
`SHA256SUMS.asc`, from each directory. Do not upload the private key, the
`dist/` build tree, or provider credentials. See
[release-checklist.md](release-checklist.md).
