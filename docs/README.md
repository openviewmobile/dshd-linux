# Linux project documentation

Language: [English README](../README.md) | [Chinese README](../README.zh-CN.md)

| Document | Contents |
|---|---|
| [architecture.md](architecture.md) | Upstream desktop fork, Linux target, runtime and packaging pipeline |
| [testing.md](testing.md) | Docker/Xvfb smoke test, real-provider E2E, format verification, evidence |
| [acceptance.md](acceptance.md) | Screen-by-screen acceptance of real conversations, Office→PDF, plugins and settings |
| [distro-packaging-implementation.md](distro-packaging-implementation.md) | AUR/Snap/OBS/Nix/Gentoo files, commands and verification boundaries |
| [release.md](release.md) | AppImage/deb/rpm/Flatpak, signing, updates and limitations |
| [release-signing.md](release-signing.md) | Release key, signing matrix, verification and private key management |
| [release-checklist.md](release-checklist.md) | Pre-release/post-release checklist |
| [github-release.md](github-release.md) | GitHub repository settings, tags and Release upload |
| [github-release-materials.md](github-release-materials.md) | Ready materials and the remaining publish blockers |
| [releases/v0.2.2-rc.1.md](releases/v0.2.2-rc.1.md) | Release notes and checksums for the current version |
| [promo.md](promo.md) | YouTube promo storyboard, render pipeline and accuracy boundaries |
| [versioning.md](versioning.md) | Version format, release channels and deprecation policy |
| [distro-support-matrix.md](distro-support-matrix.md) | Tested distros, derivatives, immutable desktops and test plan |
| [competitive-analysis.md](competitive-analysis.md) | Comparable projects, positioning and promotion playbook |
| [flathub.md](flathub.md) | Flathub requirements, app ID, manifest and submission plan |
| [appimage-update.md](appimage-update.md) | Fixed AppImage update feed, trust boundaries and test plan |
| [supply-chain.md](supply-chain.md) | SBOM, build provenance, verification and release-key rotation |
| [promotion-plan.md](promotion-plan.md) | Launch positioning, channels, copy, metrics and 30-day plan |
| [gentoo-source-build.md](gentoo-source-build.md) | Options and design for a Gentoo source/hybrid ebuild |
| [gentoo-test-plan.md](gentoo-test-plan.md) | Remaining Gentoo merge, sandbox, desktop and arm64 tests |
| [distro-packages.md](distro-packages.md) | Distribution/package-format matrix, tier recommendations, technical constraints and CI verification |
| [research/official-desktop-audit.md](research/official-desktop-audit.md) | Audit of the official desktop app and Linux release gaps |
| [adr/](adr/) | Related ADRs (Electron, forking upstream, open-source distribution, fully local scope) |

Distribution support has three tiers: Tier 1 covers the AppImage/deb/rpm/Flatpak
already produced; Tier 2 covers Arch/AUR (package built, installed and launched),
Snap (`.snap` produced, not `snap install`ed), and openSUSE OBS (local `rpmbuild`
only, no OBS server-side build); Tier 3 covers Gentoo and Nix (templates written,
statically validated), while Alpine is **explicitly unsupported** because musl is
incompatible with Electron's official glibc binaries. See
[distro-packaging-implementation.md](distro-packaging-implementation.md).

Project entry point and commands: [../README.md](../README.md).
