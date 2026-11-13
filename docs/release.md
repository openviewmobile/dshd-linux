# Linux release

> For the complete distribution/package-format matrix, tier recommendations and technical constraints, see
> [distro-packages.md](distro-packages.md); for the implemented channel files and per-item verification boundaries, see
> [distro-packaging-implementation.md](distro-packaging-implementation.md).
> x64/arm64 AppImage / deb / rpm / Flatpak have been produced; the AUR `-bin` package has been built, installed and launched;
> the Snap `.snap` and OBS RPM have been built locally, but not `snap install`ed / built on the OBS server;
> Nix / Gentoo have only templates and static checks. All release artifacts have detached GPG signatures. Alpine is
> explicitly unsupported because musl is incompatible with Electron's official glibc binaries.

## Artifacts

`package-formats.sh` / `package:linux:<arch>` produce:

| Format | Purpose |
|---|---|
| AppImage | Single file, run after `chmod +x` |
| deb | Debian/Ubuntu installation |
| rpm | Fedora/RHEL installation |
| Flatpak | Single-file bundle, manual `flatpak install` |

Both arm64 and x64 have been produced; the x64 artifacts are in `dist/linux-x64/` and include `SHA256SUMS`.

## Build

```bash
docker build -f Dockerfile -t dshd-linux-test .
docker run --rm -it -v "$PWD:/work" -v dshd-linux-src:/src dshd-linux-test
# Inside the container
/work/scripts/package-formats.sh
```

Full-format x64 rebuild:

```bash
scripts/build-flatpak-x64.sh
```

Requires the preprovisioned `dshd-linux-test:flatpak-sdk` image and the `dshd-linux-x64-src` volume; the script starts a CONNECT
proxy on the host to speed up Flathub/Electron downloads.

## GitHub Actions release build

The release workflow builds both architectures on GitHub-hosted runners:

```text
.github/workflows/release.yml
```

Trigger it by pushing a `v*` tag or with **Actions → Build Linux release assets
→ Run workflow**. It builds AppImage, deb, rpm and Flatpak inside the packaging
container, downloads the per-architecture artifacts into one release job,
creates a combined `SHA256SUMS`, signs every asset with the
`GPG_PRIVATE_KEY` repository secret, and publishes a pre-release.

Do not upload locally built binaries to the release. The workflow is the source
of truth for release assets; local `dist/` remains gitignored.

## Signing and verification

```bash
gpg --import keys/deepseek-harness-release-signing.asc
scripts/verify-artifacts.sh
DSHD_GPG_KEY=0E6023DF4DB8C68AA2202EF876CE5675AFF067FF scripts/sign-artifacts.sh
```

`SHA256SUMS` covers all x64/arm64 and AUR/Snap/OBS artifacts; every artifact and every
`SHA256SUMS` has a detached `.asc`. For the release fingerprint, signing matrix and private key management, see
[release-signing.md](release-signing.md); for the signature verification record of this release, see
`evidence/release-signing.txt`.

## Updates and distribution

- v1 has no platform code-signing certificate and no auto-updater; a manual download or a self-hosted updater is required.
- GPG detached signatures, `SHA256SUMS` and release notes are provided; an official release still requires an HTTPS download page and an
  offline release key.
- Not listed in app stores; distributed via GitHub Releases/the official website.
- The Flatpak manifest has been switched to the supported 25.08 (`patches/0002-linux-deb-rpm-flatpak.patch`;
  `runtimeVersion`/`baseVersion` are both 25.08); **the x64 25.08 bundle has been rebuilt, installed and
  launch-verified in Xvfb**, with runtime/sdk/base all at 25.08. Flatpak clears `PATH`, so
  `patches/0004-flatpak-launch.patch` adds the `/app/lib/com.deepseek.harness/dsh-launch`
  launcher and overrides the metadata `command`; **arm64 25.08 has also been built, installed and launched in Xvfb**;
  the 24.08 bundle is a historical artifact only and must not be published externally.
  Evidence: [evidence/flatpak-2508-verify.txt](../evidence/flatpak-2508-verify.txt).

## Distribution support tiers

| Tier | Channel | Status |
|---|---|---|
| Tier 1 | deb, rpm, AppImage, Flatpak bundle | Produced for x64/arm64; deb/AppImage/Flatpak (25.08 on both architectures) have install/launch verification, while rpm has only metadata/unpack checks |
| Tier 2 | Arch/AUR, Snap, openSUSE OBS | AUR `-bin` x86_64 has been built, installed with `pacman -Udd` and launched in Xvfb; Snap `.snap` has been produced (not `snap install`ed); OBS has been built locally with `rpmbuild` (not on the server) |
| Tier 3 | Gentoo, Nix/NixOS | Templates written, static validation passes; not built on the respective distributions |
| Unsupported | Alpine (musl) | Electron's official binaries are glibc-based and cannot run directly |

For the complete matrix, effort estimates and CI verification approach, see [distro-packages.md](distro-packages.md).

## Current limitations

- Office→PDF depends on the runtime engine. The `rc.1` build carried the WASM payload; the `rc.1.3` AppImage does not, so the current package may use an existing sidecar or an on-demand download. DOCX/XLSX/PPTX were tested on rc.1; pixel-perfect fidelity is not guaranteed;
- Flatpak x64/arm64 25.08 have both been verified; not submitted to Flathub;
- Snap / OBS / Nix / Gentoo have only templates and static checks, with no native build/install;
- Wayland/tray/IME have not been acceptance-tested; `desktopName` has been added but awaits confirmation on real hardware.
