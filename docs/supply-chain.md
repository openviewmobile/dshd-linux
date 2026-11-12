# Supply chain: SBOM, provenance and key rotation

## Release pipeline

The release job now produces three independent trust artifacts alongside the
packages:

1. **Detached GPG signatures** for every file, produced by the release key.
2. **SPDX SBOM** (`SBOM.spdx.json`) generated from the release directory with
   Syft/Anchore.
3. **GitHub build provenance attestation** for every file in `dist/release`,
   created with the GitHub Actions OIDC identity.

The SBOM is included in `SHA256SUMS` and signed with the same key. The
provenance attestation is stored by GitHub, not uploaded as a release asset.

## Verify

Checksums and GPG signatures:

```bash
gpg --import keys/deepseek-harness-release-signing.asc
gpg --verify SHA256SUMS.asc SHA256SUMS
sha256sum -c SHA256SUMS
```

SBOM:

```bash
python3 -m json.tool SBOM.spdx.json >/dev/null
```

GitHub attestation (requires `gh`):

```bash
gh attestation verify deepseek-harness-*.AppImage \
  --repo openviewmobile/dshd-linux
gh attestation verify deepseek-harness-*.deb \
  --repo openviewmobile/dshd-linux
```

A valid attestation proves the artifact was produced by this workflow in this
repository. It does not replace GPG verification or platform code signing.

## Formal release key rotation

The current key is the passphrase-less reference key used to bootstrap the
project. It must not be presented as the long-term production key.

### 1. Generate the new key offline

Use a machine that is not the CI runner, with the private key never committed:

```bash
gpg --quick-generate-key \
  'DSHD for Linux Release Signing <release@example.invalid>' \
  ed25519 sign 2y
gpg --armor --export-secret-keys <new-fingerprint> > release-secret.asc
gpg --armor --export <new-fingerprint> > keys/dshd-linux-release-signing.asc
```

Protect the private key with a passphrase and store an encrypted offline backup
plus the revocation certificate separately.

### 2. Update the published identity

- Replace `keys/deepseek-harness-release-signing.asc` or add a new public key
  with a clearly documented fingerprint.
- Update the fingerprint in `docs/release-signing.md`, `keys/README.md`,
  `SECURITY.md` and the release notes.
- Do not rewrite an already-published Release under an existing tag. Publish a
  new tag/Release signed with the new key; keep the old public key available for
  old artifacts.

### 3. Configure CI secrets

- `GPG_PRIVATE_KEY`: ASCII-armored private key.
- `GPG_PASSPHRASE`: passphrase for that key.
- Keep the key in a protected environment; never print it in logs.

The release workflow imports the key and uses
`--pinentry-mode loopback --passphrase` when `GPG_PASSPHRASE` is set.

### 4. Re-sign and verify

Re-sign checksums and artifacts for the new release, run
`scripts/verify-artifacts.sh`, verify the SBOM, and run
`gh attestation verify` on a fresh download.

### 5. Retire the old key

After a transition window, publish a signed revocation or deprecation note for
the reference key. Do not delete old artifacts; they remain needed for users on
older releases.
