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

## Client configuration

Host the `x86_64` directory over HTTPS, then add:

```ini
[dshd-linux]
Server = https://example.com/arch/x86_64
SigLevel = Optional
```

```bash
sudo pacman -Sy dshd-linux-bin
```

`SigLevel = Optional` is required until the repository database is signed.
For production, sign the package/database with the release key and use
`SigLevel = Required DatabaseOptional`.

## Status

The PKGBUILD is prepared and renamed from the colliding AUR name
`deepseek-harness-bin` to `dshd-linux-bin`. It is **not in AUR** and the
self-hosted repository is not yet published from CI.
