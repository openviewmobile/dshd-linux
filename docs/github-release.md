# Publishing to GitHub

See [github-release-materials.md](github-release-materials.md) for the current readiness gap list.

This repository is prepared to be published as `dshd-linux` (or a name
approved by the upstream maintainers). It is a companion repository to the
upstream application; do not rename it in a way that implies it is the
upstream source tree.

## 1. Create the repository

Suggested metadata:

- Description: `DSHD (DeepSeek Harness Desktop) for Linux: AppImage, deb, rpm, Flatpak and distro packaging`
- Topics: `linux`, `electron`, `flatpak`, `appimage`, `deb`, `rpm`, `aur`,
  `snap`, `office`, `pdf`
- License: Apache-2.0
- Default branch: `main`

Do not initialize with a README if you are pushing this tree; it already has
one.

## 2. First push

```bash
git add .
git commit -s -m "chore: prepare 0.2.2-rc.1 open-source release"
git remote add origin git@github.com:openviewmobile/dshd-linux.git
git branch -M main
git push -u origin main
```

The repository intentionally gitignores `dist/`. Never commit artifacts,
private keys, provider credentials, or `/tmp` test homes.

## 3. Repository settings

- Protect `main`: require pull requests, at least one review, status checks
  `Docs, shell syntax and manifests`, and no force pushes.
- Enable private vulnerability reporting (Settings → Code security).
- Enable Discussions if you want a support channel.
- Add `packaging`, `flatpak`, `snap`, `obs`, `aur`, `nix`, `gentoo`, `office`,
  `pdf`, `documentation`, `ci` labels used by `.github/release.yml`.
- Restrict who can create releases/tags.
- Upload `promo/out/dshd-linux-social-preview.jpg` as the repository social
  preview (Settings → General → Social preview); do not rely on the README image
  alone.

## 4. Create the release

```bash
tag=v0.2.2-rc.1
git tag -a "$tag" -m "DSHD for Linux $tag"
git push origin "$tag"

gh release create "$tag" \
  --title "DSHD for Linux $tag" \
  --notes-file docs/releases/v0.2.2-rc.1.md \
  --prerelease \
  dist/linux-x64/*.AppImage dist/linux-x64/*.AppImage.asc \
  dist/linux-x64/*.deb dist/linux-x64/*.deb.asc \
  dist/linux-x64/*.rpm dist/linux-x64/*.rpm.asc \
  dist/linux-x64/*.flatpak dist/linux-x64/*.flatpak.asc \
  dist/linux-x64/SHA256SUMS dist/linux-x64/SHA256SUMS.asc \
  dist/linux-arm64/*.AppImage dist/linux-arm64/*.AppImage.asc \
  dist/linux-arm64/*.deb dist/linux-arm64/*.deb.asc \
  dist/linux-arm64/*.rpm dist/linux-arm64/*.rpm.asc \
  dist/linux-arm64/*.flatpak dist/linux-arm64/*.flatpak.asc \
  dist/linux-arm64/SHA256SUMS dist/linux-arm64/SHA256SUMS.asc \
  dist/arch/*.zst dist/arch/*.zst.asc dist/arch/SHA256SUMS dist/arch/SHA256SUMS.asc \
  dist/snap/*.snap dist/snap/*.snap.asc dist/snap/SHA256SUMS dist/snap/SHA256SUMS.asc \
  dist/obs/*.rpm dist/obs/*.rpm.asc dist/obs/SHA256SUMS dist/obs/SHA256SUMS.asc \
  dist/keys/*.asc
```

If `gh release create` expands both `*.rpm` and the OBS RPM with the same base
name, upload the OBS asset separately with an explicit name.

## 5. Verify the published release

```bash
tmp=$(mktemp -d)
gh release download v0.2.2-rc.1 --dir "$tmp" --pattern '*SHA256SUMS*'
gh release download v0.2.2-rc.1 --dir "$tmp" --pattern '*flatpak*'
cd "$tmp"
gpg --import /path/to/keys/deepseek-harness-release-signing.asc
gpg --verify SHA256SUMS.asc SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing
```

Fetch the key fingerprint from the repository, not only from the release page.

## 6. After publishing

- Open tracking issues for Snap install, OBS service build, Nix/Gentoo builds,
  Wayland/tray/IME, and platform code signing.
- Keep the release key offline; do not add it as a plain repository secret.
- Update `CHANGELOG.md` and keep `docs/releases/` for the next tag.
