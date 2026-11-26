# Self-hosted Arch repository

AUR registration is currently closed. The supported fallback is the
`dshd-linux-bin` PKGBUILD plus a self-hosted pacman repository.

## Build locally

On Arch Linux, as a non-root user:

```bash
git clone https://github.com/openviewmobile/dshd-linux.git
cd dshd-linux
curl -L -o /tmp/deepseek-harness.AppImage \
  https://github.com/openviewmobile/dshd-linux/releases/download/v0.2.2-rc.1.5/deepseek-harness-0.2.2-rc.1.5-linux-x86_64-unsigned.AppImage
scripts/build-arch-repo.sh /tmp/deepseek-harness.AppImage
```

The script uses `packaging/aur/PKGBUILD`, builds `dshd-linux-bin`, and writes:

```text
dist/arch-repo/x86_64/dshd-linux-bin-*.pkg.tar.zst
dist/arch-repo/x86_64/dshd-linux.db.tar.gz
dist/arch-repo/x86_64/dshd-linux.files.tar.gz
```

## Hosted repository

The Pages workflow builds the package from `packaging/arch/PKGBUILD-ci` and
publishes the pacman database. The `Package repository install smoke` workflow
installs `dshd-linux-bin` from this repository in an Arch container and checks
the binary, desktop entry and icon.

```text
https://openviewmobile.github.io/dshd-linux/arch/x86_64
```

For a local build, configure:

```ini
[dshd-linux]
Server = https://openviewmobile.github.io/dshd-linux/arch/x86_64
SigLevel = Required DatabaseOptional
PackageSigLevel = Optional
```

The repository database and package are signed with the release key. Import it
first:

```bash
curl -fsSL https://openviewmobile.github.io/dshd-linux/key.asc \
  | sudo pacman-key --add -
sudo pacman-key --lsign-key <fingerprint>
```

```bash
sudo pacman -Sy dshd-linux-bin
```

`SigLevel = Optional` is required until the repository database is signed.
For production, sign the package/database with the release key and use
`SigLevel = Required DatabaseOptional`.

## Status

The AUR-facing PKGBUILD is renamed to `dshd-linux-bin` and is **not in AUR**.
The Pages workflow uses a separate `packaging/arch/PKGBUILD-ci` with no remote
source arrays; the workflow supplies the AppImage and checksum explicitly.
