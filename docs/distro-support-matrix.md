# Distribution support matrix

This page separates **tested**, **expected-compatible derivatives**, **Flatpak-only
immutable systems**, and **packaging recipes**. “Expected-compatible” means the
existing deb/rpm/AppImage is designed to work, but the distribution has not yet
been through the full install + launch acceptance in this repository.

## Tested or directly supported

| Distribution | Package path | Evidence |
|---|---|---|
| Debian 12/13 | Release `.deb` or x86_64 APT repository | x64 deb installed/launched in Docker + Xvfb; arm64 structure checked |
| Ubuntu 22.04/24.04 | Release `.deb` or x86_64 APT repository | x64 deb path; 24.04 t64 dependency names measured |
| Fedora 41/42 | Release `.rpm` or x86_64 DNF repository | rpm metadata/unpack checked; full Fedora install pending |
| RHEL / Rocky Linux 9 | Release `.rpm` or x86_64 DNF repository | glibc baseline; install on target pending |
| Arch Linux / Manjaro | `packaging/aur` recipe (not in AUR) | x86_64 built/installed/launched under Xvfb |
| Any glibc desktop | Release AppImage or Flatpak bundle | AppImage launched on x64/aarch64; Flatpak 25.08 installed/launched |

## High-value derivatives to add next

These can reuse the existing primary artifacts. The work is mostly test images,
documentation, and package-manager verification rather than new binaries.

| Distribution | Base / family | Suggested package | Why it is valuable | Status |
|---|---|---|---|---|
| Linux Mint 22 | Ubuntu 24.04 | `.deb` (APT) | Large desktop install base; users expect `apt install` | Test |
| Pop!_OS 22.04/24.04 | Ubuntu | `.deb` (APT) | System76/developer desktop; COSMIC users | Test |
| Zorin OS 17/18 | Ubuntu | `.deb` (APT) | Consumer-friendly desktop; new Linux users | Test |
| elementary OS 7/8 | Ubuntu | `.deb` (APT) | Design-focused desktop; visible community | Test |
| MX Linux 23 | Debian 12 | `.deb` | Popular Debian desktop; conservative users | Test |
| Raspberry Pi OS 64-bit | Debian arm64 | `.deb` arm64 / AppImage arm64 | Large aarch64 desktop base; Pi 4/5 | Test on Pi |
| AlmaLinux 9 | RHEL 9 | `.rpm` (DNF) | Enterprise desktop/server reach | Test |
| CentOS Stream 9 | RHEL 9 | `.rpm` (DNF) | Developer/enterprise preview base | Test |
| Oracle Linux 9 | RHEL 9 | `.rpm` (DNF) | Enterprise deployments | Test |
| Nobara 41/42 | Fedora | `.rpm` | Gaming/desktop-focused Fedora derivative | Test |
| Kali Linux rolling | Debian testing | `.deb` (best effort) | Security desktop audience; dependency drift risk | Experimental |
| Parrot OS | Debian | `.deb` (best effort) | Security desktop audience | Experimental |
| Deepin 23 / UOS | Debian-derived | `.deb` (best effort) | Chinese desktop ecosystem | Experimental |
| Devuan 5 | Debian without systemd | `.deb` | Users explicitly avoiding systemd | Experimental |
| PureOS | Debian | `.deb` | Privacy-focused desktop | Experimental |

Notes:

- Linux Mint, Pop!_OS, Zorin and elementary use Ubuntu bases; verify the exact
  Ubuntu version and `t64` transition before claiming support.
- MX Linux is Debian stable-based; use the Debian 12 test image first.
- Kali/Parrot/Deepin are not simply “Debian stable”: dependency and library
  drift can break a binary package. Keep them experimental until tested.
- Raspberry Pi OS must be the **64-bit** image. 32-bit/armhf is not supported.

## Immutable / atomic desktops

These should use the **Flatpak bundle** (or AppImage) rather than layering RPMs
into the immutable root. Do not document `sudo dnf install` as the primary path.

| Distribution | Preferred path | Notes |
|---|---|---|
| Fedora Silverblue / Kinoite | Flatpak | rpm-ostree layering is possible but not recommended for an Electron app |
| Bazzite | Flatpak | Fedora Atomic gaming desktop |
| SteamOS 3 | Flatpak | Read-only Arch-based root; do not document `pacman -S` |
| openSUSE Aeon / MicroOS | Flatpak | Transactional/immutable base |
| Endless OS | Flatpak | OSTree-based desktop |

## Arch-family derivatives

| Distribution | Path | Status |
|---|---|---|
| EndeavourOS | AUR recipe / Arch package | Test recipe |
| CachyOS | AUR recipe / Arch package | Test recipe |
| Garuda Linux | AUR recipe / Arch package | Test recipe |
| Manjaro | AUR recipe / Arch package | Already tested on Arch x86_64; Manjaro-specific QA pending |

An **Arch custom repository** could be hosted on GitHub Pages, but it requires a
CI-built `.pkg.tar.zst`; it is not part of the current Release. AUR publication
is a separate external channel.

## Recipes and external channels

| Channel | Status |
|---|---|
| openSUSE OBS | local `rpmbuild` only; no OBS repository |
| NixOS | flake recipe; not built on NixOS |
| Gentoo | ebuild recipe; not built on Gentoo |
| Snap | PoC; not in Snap Store |
| Alpine | unsupported (musl) |
| Void Linux (glibc) | AppImage trial only; no xbps package |
| Solus | no package; low priority |
| Slackware | no package; low priority |

## Recommended order

1. Linux Mint + Pop!_OS (reuse Ubuntu deb; broad desktop reach)
2. Raspberry Pi OS 64-bit (reuse arm64 deb; unique ARM reach)
3. AlmaLinux / CentOS Stream / Oracle Linux (reuse RHEL rpm)
4. Fedora Silverblue/Kinoite + Bazzite (Flatpak documentation and test)
5. SteamOS 3 (Flatpak only; gaming audience)
6. Nobara, MX Linux, Zorin/elementary, Deepin/UOS (as test capacity allows)
7. Arch custom repository or AUR publication, then Nix/Gentoo/Snap

## Acceptance checklist for a new derivative

- Install from the released artifact, not a local build.
- Launch under the real desktop session; record X11/Wayland.
- Create a session and complete a real-provider chat round trip.
- Convert DOCX/XLSX/PPTX and one legacy format to PDF.
- Install, enable, and remove a plugin.
- Verify APT/DNF metadata and signatures if using a repository.
- Record the exact image/version, architecture, kernel, and desktop in
  `evidence/`; add the distro to the README table only after it passes.
