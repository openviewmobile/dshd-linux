# Publishing to GitHub

See [github-release-materials.md](github-release-materials.md) for the current readiness gap list.

This repository is prepared to be published as `dshd-linux` (or a name
approved by the upstream maintainers). It is a companion repository to the
upstream application; do not rename it in a way that implies it is the
upstream source tree.

## 1. Create the repository

Suggested metadata:

- Description: `DSHD (DeepSeek Harness Desktop) for Linux: AppImage, deb, rpm, Flatpak and distro packaging`
- Topics: `dsh`, `deepseek-harness`, `deepseek`, `ai`, `linux`, `appimage`,
  `deb`, `rpm`, `flatpak`, `archlinux`, `aur`, `debian`, `ubuntu`, `fedora`,
  `rhel`, `rocky-linux`, `opensuse`, `nixos`, `gentoo`
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

## 4. Publish from GitHub Actions only

The public Release is produced by
[`.github/workflows/release.yml`](../.github/workflows/release.yml). Pushing a
`v*` tag triggers x86_64 and aarch64 runners to build AppImage, deb, rpm and
Flatpak, sign the combined checksums, and upload the assets. The same workflow
can be run manually from **Actions → Build Linux release assets**.

```bash
tag=v0.2.2-rc.1
git tag -a "$tag" -m "DSHD for Linux $tag"
git push origin "$tag"
```

**Do not** create the public Release with local files, and do not upload
locally built binaries or local `dist/` content. The workflow is the source of
truth; local artifacts are development outputs only. If the workflow fails,
fix the workflow or rerun it — do not publish a partial local release.

The workflow requires the `GPG_PRIVATE_KEY` repository secret. It publishes a
pre-release with the eight primary-format packages, their `.asc` files, the
combined `SHA256SUMS`/`SHA256SUMS.asc`, and the public key.

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
