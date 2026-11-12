# Changelog

All notable changes to the Linux desktop distribution project are documented
here. This project follows [Semantic Versioning](https://semver.org/) for the
packaging version and mirrors the upstream desktop version in the package
version.

## [Unreleased]

### Changed

- English is now the primary project README (`README.md`); the complete Chinese
  README is available at `README.zh-CN.md`.
- Added the upstream MIT license text under `LICENSES/` and corrected the
  security and documentation-link guidance in the contributor files.
- Migrated all `docs/` Markdown to English and added the `docs/promo.md`
  storyboard/render notes.
- Added a 50-second Three.js/hyper-frame YouTube promo, thumbnail, English and
  Chinese captions, and upload metadata under `promo/`.
- Added a GitHub Actions workflow that builds and signs Linux release assets
  for x86_64 and arm64 on hosted runners.
- Added signed APT (Debian/Ubuntu) and DNF (Fedora/RHEL/Rocky) repositories
  hosted on GitHub Pages for x86_64, plus a package landing page.
- Added project governance, support policy, roadmap, versioning policy,
  CODEOWNERS, Dependabot and CodeQL.

## [0.2.2-rc.1] - 2026-11-10

First Linux release candidate prepared for public distribution.

### Added

- Linux x64 and arm64 desktop targets and AppImage/deb/rpm/Flatpak artifacts.
- Flatpak manifests using `org.freedesktop.Platform//25.08`,
  `org.freedesktop.Sdk//25.08` and `org.electronjs.Electron2.BaseApp//25.08`
  for both architectures.
- A Flatpak launcher that restores `PATH` and sets the bundle metadata
  `command` to `/app/lib/com.deepseek.harness/dsh-launch`.
- Arch/AUR `-bin` packaging with `.SRCINFO`, architecture-aware sources and an
  offline `DSHD_APPDIR` build path.
- Snap `snapcraft.yaml`, a proof-of-concept `.snap` assembled with squashfs,
  and a strict-confinement wrapper.
- openSUSE OBS spec/service files for a binary RPM repackage.
- Nix flake/derivation and Gentoo ebuild (packaging files only in this
  release; not built in the reference environment).
- PDF and Office export validation covering DOCX, PPTX, XLSX, and legacy
  DOC/XLS/PPT, including the bundled WASM backend and a third-party plugin.
- Detached GPG signatures for every release artifact and checksum file, with a
  published release public key under `keys/`.
- Apache-2.0 license, NOTICE, contribution/security/conduct guides, issue and
  pull-request templates, and a release checklist.

### Fixed

- Flatpak startup failed because the BaseApp's `electron-wrapper` could not be
  found after Flatpak cleared `PATH`; the bundle now ships `dsh-launch`.
- Flatpak runtime `24.08` was end-of-life; both architectures moved to `25.08`.
- AUR packages built from an extracted AppDir on a non-Linux host lost the
  executable bit; `package()` now restores modes for the launcher, crash handler
  and runtime `bin/*` entries.
- Legacy Office files (.doc/.xls/.ppt) previously lacked dedicated test
  coverage; they now have per-format conversion and rendered-page evidence.

### Known limitations

- Artifacts are GPG-signed detached signatures; they are not signed with a
  platform code-signing certificate and filenames keep the historical
  `unsigned` suffix.
- Snap was not installed with `snap install`; confinement behavior is not
  verified. OBS was built with a local `rpmbuild`, not on the OBS service.
- Nix and Gentoo packaging was not built in the reference environment.
- Wayland-native sessions, tray integration and IME behavior are not verified
  on physical desktops.
- The bundled LibreOfficeKit WASM converter is the supported office backend;
  native LibreOffice is not required or used.

[0.2.2-rc.1]: docs/releases/v0.2.2-rc.1.md
