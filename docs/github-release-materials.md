# GitHub release materials

Status: **source and tag published** at
<https://github.com/openviewmobile/dshd-linux>; CI passed and the GitHub Release
asset upload is still pending. The remaining items below are the post-push
gaps.

## Ready in the tree

- Apache-2.0 `LICENSE`, `NOTICE`, and the upstream MIT text in
  `LICENSES/MIT-DeepSeek-Harness.txt`;
- English `README.md`, Chinese `README.zh-CN.md`, `CONTRIBUTING.md`,
  `SECURITY.md`, `CODE_OF_CONDUCT.md`, and the English `docs/` tree;
- issue forms, pull-request template, release-note categories, and CI;
- release notes in `docs/releases/v0.2.2-rc.1.md`;
- signing instructions and a public reference key in `keys/`;
- AppImage, deb, rpm, and Flatpak for x86_64/aarch64; AUR, Snap, and OBS
  packages; `SHA256SUMS` and detached signatures in `dist/`;
- acceptance evidence in `evidence/`;
- YouTube promo, thumbnail, subtitles, upload copy, and GitHub social preview in
  `promo/`.

## Remaining publish steps

1. **Owner and repository name (done).** `openviewmobile/dshd-linux`; the docs
   and upload metadata use this target.
2. **Replace the reference signing key.** The current key is passphrase-less and
   uses an `.invalid` UID. Generate an offline, passphrase-protected release key,
   publish its fingerprint, re-sign all artifacts, and archive the revocation
   certificate.
3. **Upload the GitHub Release assets.** The annotated tag
   `v0.2.2-rc.1` is pushed; upload the artifacts listed in
   [github-release.md](github-release.md), mark the release as a pre-release,
   and verify a fresh download.
4. **Finish the CI matrix.** Current CI validates docs, shell syntax, YAML, and
   required files. It does not build the packages or run install/launch tests in
   distribution images, and there is no automated release/signing workflow.
5. **Configure GitHub.** Protect `main`, enable private vulnerability reporting,
   add the labels used by `.github/release.yml`, set the description/topics, and
   upload `promo/out/dshd-linux-social-preview.jpg` as the social preview.
6. **Resolve brand/trademark use.** `NOTICE` grants no trademark license. Confirm
   that the DeepSeek name/logo may be used in the repository and promo, or add a
   clear independence disclaimer approved by the trademark owner.
7. **Decide the YouTube owner.** Upload requires a Google account/channel with
   permission to publish; no credentials or channel are configured here.

## Release assets

The local `dist/` tree is 3.0 GB and contains 17 `.asc` files: one public key
plus 16 artifact/checksum signatures. Upload the per-format artifacts and their
signatures as described in
[github-release.md](github-release.md#4-create-the-release). Keep `dist/` out of
git.

The promo video (`promo/out/dshd-linux-promo-1080p.mp4`, 8.8 MB) is a YouTube
asset, not a required GitHub Release asset. It can be attached to the release
or hosted separately.

## Unverified channels must stay labeled

Snap and OBS were built locally but were not installed from the Snap Store or
built on the OBS service. Nix/Gentoo are static checks only. Wayland, tray, IME,
platform code-signing, and auto-update remain unverified. The release notes and
video repeat these limits; keep them in the announcement.
