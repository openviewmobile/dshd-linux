# Roadmap

This is a living priority list, not a promise of dates. Issues and pull requests
that include reproducible evidence move faster.

## Now — release quality

- Complete real install + launch acceptance for Debian, Ubuntu, Fedora, Rocky,
  Arch, openSUSE and Flatpak on both supported architectures.
- Run `apt install` and `dnf install` end-to-end against the GitHub Pages
  repositories, not only metadata/signature checks.
- Restore a packaged Office→PDF smoke test with the WASM backend; document the
  current upstream native LibreOfficeKit fallback.
- Replace the reference release key with an offline, passphrase-protected key;
  re-sign and publish the fingerprint.
- Add an SBOM and build provenance/attestations to release assets.
- Reconcile `CHANGELOG`, release notes, sizes, checksums, and the release
  checklist for every release.

## Next — distribution and desktop integration

- aarch64 APT/DNF (separate Pages site or object storage).
- Arch custom repository (x86_64) and/or AUR publication.
- Flathub submission or a self-hosted Flatpak OSTree repository.
- Snap Store publication if strict confinement can be made usable.
- openSUSE OBS, Nix and Gentoo builds in their native environments.
- Wayland, tray icon, IME and desktop-file integration on physical desktops.
- User-facing diagnostics for Provider/network/Office failures.

## Later — product and community

- Auto-update or explicit update-check UX; platform code signing where it adds
  meaningful trust.
- Stable `v0.2.2` release after the RC acceptance gaps are closed.
- More maintainers and reviewers; documented release rotation.
- Accessibility and localization review for the welcome and settings flows.

## Non-goals

- Replacing the upstream DeepSeek Harness source tree.
- Supporting Alpine/musl without a verified Electron rebuild.
- Uploading locally built binaries to the public Release.
- Claiming an untested distribution is “supported”; unverified channels remain
  labeled as packaging recipes.

## Proposing work

Open an issue with the user problem, target distribution/architecture, proposed
change, and evidence plan. For security work, use the private advisory flow.
