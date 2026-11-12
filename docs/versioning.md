# Versioning and release policy

## Version format

The packaging version follows [Semantic Versioning](https://semver.org/) and
mirrors the upstream desktop version where practical:

- release candidate: `0.2.2-rc.1`, tag `v0.2.2-rc.1`
- stable: `0.2.2`, tag `v0.2.2`
- packaging-only fix: `0.2.2-1` or a documented revision suffix

AUR uses `_` in `pkgver` (`0.2.2_rc.1`) because `-` is reserved by pacman.

## Channels

| Channel | Version source | Notes |
|---|---|---|
| GitHub Release | tag | Pre-releases use `prerelease: true` |
| APT/DNF Pages | latest published Release | x86_64 only at present |
| AppImage/deb/rpm/Flatpak | Release asset | Manual updates |
| Arch/AUR, Nix, Gentoo, Snap | package recipe | Verification status in README |

## Release rules

1. `main` is green in CI.
2. The release checklist is completed and evidence is linked.
3. The tag is annotated and pushed; the release workflow builds and signs the
   assets.
4. Release notes list tested platforms, known limitations, and the signing key
   fingerprint.
5. A release candidate is not relabeled stable without closing its acceptance
   gaps.
6. Never move a published release tag to a different commit; publish a new
   version instead.
7. Local binaries are never uploaded to a public release.

## Deprecation

When a distribution or format is no longer supported, mark it in the README
support table, keep the last available artifact, and add a migration note to the
next release notes.
