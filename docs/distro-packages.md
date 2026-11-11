# Linux Distribution and Package Format Support Research

> Status: **research / planning document (2026-11-10)**. This document does not rebuild
> artifacts; whether a format is "implemented" is determined by the repository's existing
> patches, scripts, and `evidence/`; parts that are not implemented are explicitly marked
> "planned" or "unsupported".
>
> Bottom line up front:
>
> - **Produced and verified**: AppImage, deb, rpm, Flatpak (single-file bundle), for both arm64 and x64.
> - **New packaging files added**: AUR `-bin` (package produced, installed with `pacman -Udd`
>   and launched under Xvfb), Snap (a `.snap` was produced by hand, but no `snap install`),
>   openSUSE OBS (local `rpmbuild` only), Nix/NixOS, Gentoo; see
>   [distro-packaging-implementation.md](distro-packaging-implementation.md).
> - **Signing**: all release artifacts and `SHA256SUMS` already have detached GPG signatures, see
>   [release-signing.md](release-signing.md).
> - **Still incomplete**: Flathub/store listing, platform code signing, automatic updates,
>   Snap installation and OBS server-side builds, Nix/Gentoo builds, and on-hardware
>   acceptance of Wayland/tray/input methods.
> - **Hard constraint**: Alpine is musl and official Electron prebuilt artifacts are glibc, so
>   they **cannot run directly**; this is not a packaging problem but a runtime ABI problem.
> - **Flatpak runtime**: the manifest has moved to the supported 25.08; 24.08 reached
>   **EOL in 2026-09**, and old bundles are only internal historical artifacts.
>   **25.08 for both x64 and arm64 has been rebuilt, installed, and launch-verified**.
> - **Recommended support baseline**: glibc ≥ 2.32, i.e. Debian 12+, Ubuntu 22.04+, RHEL 9+,
>   openSUSE Leap 15.6+, Arch, Gentoo, NixOS; RHEL 8 / Debian 11 / Ubuntu 20.04 are
>   not promised (reasons in [§4.2](#42-glibc-baseline-and-artifact-measurements)).

---

## 1. The Actual State of the Current Repository

The existing Linux packaging pipeline is described in [architecture.md](architecture.md),
[release.md](release.md), and [testing.md](testing.md). The build entry points are
[scripts/package-formats.sh](../scripts/package-formats.sh) and [Dockerfile](../Dockerfile);
format configuration lives in
[patches/0002-linux-deb-rpm-flatpak.patch](../patches/0002-linux-deb-rpm-flatpak.patch).

| Format | Architecture | Version / size | What has been verified | Status |
|---|---|---|---|---|
| AppImage | arm64 / x64 | 0.2.2-rc.1; about 349 MB / 354 MB | Launched under Xvfb; window and Host work normally | ✅ Produced; unsigned, no auto-update |
| deb | arm64 / x64 | 262 MB / 278 MB | `dpkg-deb -I` metadata; x64 installed and launched in an amd64 Docker container + Xvfb | ✅ Produced; no APT repo |
| rpm | arm64 / x64 | 216 MB / 229 MB | `rpm -qpi` metadata; no installation on real Fedora/RHEL hardware | ✅ Produced; no DNF repo |
| Flatpak | arm64 / x64 | 227 MB / 240 MiB | 25.08 bundle installation for both architectures, ref/runtime checks, Xvfb GUI launch | ✅ x64/arm64 25.08 verified; **not submitted to Flathub** |
| Snap | — | — | — | 🟡 `.snap` produced, no `snap install` |
| Arch `pkg.tar.zst` / AUR | — | — | — | ✅ Package produced, installed, and launched |
| openSUSE OBS repository | — | — | — | 🟡 Local rpmbuild produced a package; no server-side OBS build |
| Alpine `apk` | — | — | — | ⛔ Incompatible (musl) |
| Gentoo ebuild | — | — | — | ⚪ Not implemented (research) |
| Nix / NixOS | — | — | — | ⚪ Not implemented (research) |

Evidence:

- [evidence/formats-verification.txt](../evidence/formats-verification.txt) (arm64 deb/rpm/Flatpak metadata and SHA-256);
- [evidence/flatpak-2508-verify.txt](../evidence/flatpak-2508-verify.txt) (x64 Flatpak 25.08, `com.deepseek.harness/x86_64/master`,
  `org.freedesktop.Platform/x86_64/25.08`, installation and launch);
- [evidence/flatpak-x64-smoke.txt](../evidence/flatpak-x64-smoke.txt) (Flatpak GUI smoke test inside Docker; a real host does not need the bwrap workaround);
- [evidence/signing.txt](../evidence/signing.txt) (test GPG signing only; **not a release signature**).

The application itself: `@deepseek-ai/dsh-desktop@0.2.2-rc.1`, Electron **44.7.0** (Chromium 152 / Node 24.21),
bundling Node, pnpm, Python, ripgrep, and the dsh production dependencies. For Electron 44's platform support policy see the
[Electron v44.7.0 README](https://github.com/electron/electron/blob/v44.7.0/README.md):
the official x64/arm64 Linux binaries are **built on Ubuntu** and only versions still supported by both Chromium and the distribution are promised.

---

## 2. Overview Matrix

> "Relative scale" is an order-of-magnitude judgment for planning, not precise installed-base statistics. There is no
> authoritative distribution-level share data for the Linux desktop; it is used here only for ranking, not as a release promise.
>
> Status legend: ✅ produced and verified; ⚠️ produced but with obvious gaps; ⚪ planned/research; ⛔ explicitly unsupported.

| Distribution / channel | Target users and relative scale | Native format and tooling | Build / signing | Sandbox / updates | Dependencies / runtime | Estimated effort | Current repo status | Main gaps / risks |
|---|---|---|---|---|---|---|---|---|
| **Debian / Ubuntu and derivatives** (Ubuntu, Mint, Pop!_OS, Kali, Deepin, etc.) | Largest tier of desktop Linux; Ubuntu dominant, Debian second | `deb` + APT; `dpkg-deb`, `reprepro`/`aptly` | electron-builder + fpm; `debsigs`/repo `Release.gpg`; `lintian` | No application sandbox; APT repo or manual download; no built-in updater | Depends on system GTK3/NSS/X11 etc.; Electron/Node/Python fully bundled; glibc | 1–2 person-days per release to maintain; +2–3 person-days to build an APT repo | ✅ deb produced (arm64/x64) | No APT repo; Ubuntu 24.04 t64 already provides the old names, Debian 13/arm64 still to be tested; unsigned |
| **Fedora / RHEL / CentOS Stream / Rocky / Alma** | Second largest tier; Fedora desktop + RHEL workstation/enterprise | `rpm` + DNF/YUM; `rpmbuild`, `createrepo_c` | electron-builder + fpm; `rpmsign`/`rpm --addsign`; `rpmlint` | No application sandbox; DNF repo or manual; no built-in updater | `gtk3`, `nss`, `libnotify`, `libXScrnSaver`, `at-spi2-core`, `xdg-utils`, `libXtst`, `libuuid`; glibc | 1–2 person-days per release to maintain; +2 person-days for multi-version verification | ✅ rpm produced (arm64/x64) | RHEL 8 (glibc 2.28) is below the baseline; RHEL 7/CentOS 7 are EOL (YUM unsupported); no installation on real hardware; unsigned |
| **openSUSE / SLES** | Niche but stable; European enterprises and the SUSE ecosystem | `rpm` + Zypper; OBS can produce rpm/deb/AppImage at once | OBS (`osc`, `_service`, spec); OBS project-key signing; `rpmlint` | No application sandbox; OBS repo + `zypper up` | Same RPM family, slightly different package names; glibc | 3–5 person-days to set up an OBS project; 1 person-day per release | 🟡 Local rpmbuild produced a package | Needs a separate spec/`_service`; SELinux/AppArmor unverified; OBS builds have no network |
| **Arch / Manjaro / EndeavourOS** | High density of developers/technical users; moderate total | `pkg.tar.zst` + pacman; AUR | `makepkg`, `namcap`; `makepkg --sign` / pacman-key | No application sandbox; `pacman -Syu`; AUR helper | System GTK3/NSS etc.; **must bundle Electron** (see §4.4) | AUR `-bin` 2–3 person-days; native 5–8 person-days | ✅ Package produced, installed, and launched | System `electron` cannot be used for `ELECTRON_RUN_AS_NODE`; AUR is not an official repository; rolling-upgrade ABI risk |
| **Alpine Linux** | Mostly servers/containers, very few desktops | `apk`; `abuild` | `abuild -r`, `abuild-sign`, `apk index`; APKBUILD | No application sandbox; `apk upgrade` | **musl**; official Electron is glibc; Alpine `testing/electron` is a musl rebuild from source and lags in version | 15–30 person-days and very likely infeasible | ⛔ Unsupported | Official Electron binaries cannot run; gcompat is unreliable; would require rebuilding Electron + native modules + Python from source |
| **Gentoo** | Very niche; source/technical users | `ebuild` + Portage | `ebuild`, `pkgcheck`, `repoman`; GPG-signed Manifest | No application sandbox; `emerge -u` | System glibc libraries; can unpack the AppImage or bundle Electron | 5–8 person-days | ⚪ Not implemented | No generic Electron ebuild in the main tree (as of this research); QA/license review; rolling ABI |
| **NixOS / Nix** | Niche but growing fast; developers/reproducible-build users | Nix derivation / flake | `nix-build`, `nix flake check`, `nixpkgs-review`; binary cache signing | No runtime sandbox; `nix profile upgrade` / `nixos-rebuild` | nixpkgs libraries + `autoPatchelfHook`; official Electron or nixpkgs Electron | 5–10 person-days | ⚪ Not implemented | Official Electron and nixpkgs versions may diverge; setuid sandbox unavailable in the read-only store; needs FHS/patchelf handling |
| **Snap** (snapd / Snap Store) | Preinstalled on Ubuntu, broad reach; usable across distributions | `snap`; snapcraft | `snapcraft pack`, `snapcraft lint`; Store review/signing | AppArmor + seccomp; snapd auto-refresh; channels | `base: core24` provides the Ubuntu 24.04 userland; the app bundles Electron; `stage-packages` for extra libraries | PoC 5–8 person-days; store review 2–6 weeks | 🟡 Hand-built `.snap` produced, not installed | dsh needs local shell/files/network, so strict permissions may not suffice; classic confinement requires manual Store approval |
| **Flatpak** (Flathub / self-hosted OSTree) | Cross-distribution; Flathub growing fast | `.flatpak` bundle / OSTree repo | `flatpak-builder`, `flatpak build-sign`, `flatpak build-update-repo`; `flatpak-builder-lint` | bubblewrap sandbox; `flatpak update`; Portals | `org.freedesktop.Platform//25.08` + `org.electronjs.Electron2.BaseApp//25.08` | 2–4 person-days per release to maintain; 3–5 person-days to upgrade the runtime; 15–30 person-days to make it source-built for Flathub | ✅ x64/arm64 25.08 verified | Not on Flathub; Flathub requires building from source and forbids prebuilt binaries; developer-tool apps face strict review |
| **AppImage** | Download-based distribution; developers/users who don't want to install packages | `.AppImage` (type 2) | electron-builder + `appimagetool`; `--sign`; zsync/update information | No sandbox; manual download; optional AppImageUpdate | Bundles Electron/Node/Python; depends on system GTK3/NSS etc.; glibc | 0.5–1 person-day per release to maintain | ✅ Produced (arm64/x64) | No auto-update; unsigned; Ubuntu 24.04 userns restrictions may affect the Chromium sandbox; large size |

Additional notes:

- **CentOS Linux 8** is EOL; **CentOS Stream 9/10** is the current path; **RHEL 7/CentOS 7**
  and their YUM ecosystem are EOL and out of scope.
- **Deepin / UOS** use deb, but their desktop environment and system library versions differ
  substantially; treat them as Debian derivatives and verify separately.
- **portable tar.gz** is not listed as a formal format: it solves neither dependencies, desktop
  integration, updates, nor signing, so it is less valuable than AppImage; if needed, it can be
  a debugging/CI artifact but not a user distribution format.

---

## 3. Per-Distribution / Format Details

### 3.1 Debian / Ubuntu and derivatives (deb / APT)

**Target users.** Ubuntu is the de facto default choice for desktop Linux, and Debian stable covers servers and conservative desktops;
Mint, Pop!_OS, Kali, Deepin, and others reuse deb directly. This family should be the first priority.

**Format and tooling.** `deb` is generated by electron-builder's fpm backend; it is essentially an `ar` archive +
`control.tar.xz` + `data.tar.xz`. For the specification see the
[Debian Policy](https://www.debian.org/doc/debian-policy/) and the
[Ubuntu Packaging Guide](https://packaging.ubuntu.com/html/). For quality checks use
[Lintian](https://lintian.debian.org/). Repository publishing usually uses `reprepro` or `aptly` to generate
`Packages`/`Release`, signed by `Release.gpg`; individual package signing can use `debsigs`/`dpkg-sig`
(the latter is no longer recommended).

`Depends` of the current artifact (measured):

```text
libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6, xdg-utils,
libatspi2.0-0, libuuid1, libsecret-1-0
Recommends: libappindicator3-1
```

**Risks.**

1. **t64 package renaming**: starting with Ubuntu 24.04 / Debian 13, `libgtk-3-0`, `libatspi2.0-0`, etc. became
   `libgtk-3-0t64`, `libatspi2.0-0t64`. The current deb metadata still lists the old names. It has been measured that on Ubuntu 24.04
   the t64 packages provide the old names (`libgtk-3-0t64`'s `Provides:` includes `libgtk-3-0`;
   `libatspi2.0-0t64` provides `libatspi2.0-0`; likewise `libatk1.0-0t64`/`libcups2t64`),
   so in theory they resolve; but Debian 13, arm64, and actual installation still need to be verified on the target images,
   not just by inspecting metadata.
2. **No APT repository**: currently only a single-file deb, which users must download manually; there is no `apt upgrade` path.
3. **No release signing**: `SHA256SUMS` only has a test GPG signature, see [evidence/signing.txt](../evidence/signing.txt).
4. **Expected Lintian warnings**: embedded Electron/Node, no manpage, `Section: default`,
   maintainer scripts, etc.; an acceptable warning baseline needs to be defined.

**Update model.** deb does not ship an updater. Options: a self-hosted APT repository (recommended, using `apt`'s native updates);
or implementing a custom in-app updater (high effort, complex permissions). Relying on electron-updater's
Linux deb path as the sole solution is not recommended.

**Verification.** See [§5](#5-verification-and-ci-matrix).

**Effort.** 1–2 person-days per release to maintain the existing format; 3–5 person-days to add an APT repository, signing, and multi-version verification.

---

### 3.2 Fedora / RHEL / CentOS Stream / Rocky / Alma (rpm / DNF/YUM)

**Target users.** Fedora is the desktop/development distribution that adopts new technology fastest; RHEL, Rocky, and Alma cover enterprise
workstations and managed desktops; CentOS Stream is the RHEL upstream. RHEL 8 and earlier have glibc 2.28, below
this project's baseline, and are **not promised**; RHEL 9/10 and the corresponding clones are the targets.

**Format and tooling.** `rpm` is generated by fpm. For the specification see the
[Fedora Packaging Guidelines](https://docs.fedoraproject.org/en-US/packaging-guidelines/) and the
[RPM Packaging Guide](https://rpm-packaging-guide.github.io/). For checks use
[rpmlint](https://github.com/rpm-software-management/rpmlint); for signing use `rpmsign --addsign`
or `rpm --addsign`; for repositories use `createrepo_c` + DNF's `repo_gpgcheck`.

`Requires` of the current artifact (measured; auto-generated soname/package-name dependencies):

```text
gtk3, nss, libnotify, libXScrnSaver, at-spi2-core,
xdg-utils, (libXtst or libXtst6), (libuuid or libuuid1), /bin/sh
```

Note: the rpm generated by fpm has **no** `Recommends:` weak dependencies, so `libappindicator-gtk3`,
needed for the tray icon, is not installed automatically; the Debian side has `Recommends: libappindicator3-1`,
while the rpm side needs `Recommends`/`Suggests` added explicitly in the spec, or an explanation in the docs.

**Risks.**

1. **RHEL 8 / CentOS 8**: glibc 2.28, below the 2.32 baseline in §4.2; should not be released.
2. **SELinux**: the setuid `chrome-sandbox` under `/opt/DeepSeek Harness` may trigger
   `selinux` denials; verify on enforcing Fedora/RHEL and, if necessary, ship a policy or switch to the
   user namespace sandbox.
3. **No DNF repository**: currently only a single-file rpm; enterprise environments usually need an internal repository.
4. **No installation on real hardware**: currently only `rpm -qpi` metadata checks; there is no install+start evidence from Fedora/Rocky.

**Update model.** A self-hosted DNF repository (`createrepo_c` + GPG signing) best matches the native experience; otherwise manual
download. The in-app updater is likewise not wired up.

**Effort.** 1–2 person-days per release to maintain; 3–5 person-days for multi-version verification and spec adjustments
across RHEL 9/10, Rocky, and Fedora; +2 person-days to set up a repository.

---

### 3.3 openSUSE / SLES (rpm / Zypper / OBS)

**Target users.** Enterprise/European users of openSUSE Leap/Tumbleweed and SLES; the total is not large, but
openSUSE's OBS can build and publish rpm, deb, and AppImage together, making it a high-leverage channel of
"invest once, produce many formats".

**Format and tooling.** At runtime it is still rpm + Zypper, but **maintaining a second hand-written rpm build is not recommended**; use
[Open Build Service (OBS)](https://openbuildservice.org/help/manuals/obs-user-guide/) instead:

- the `osc` client + a project (start with `home:<user>`, submit to a devel project once mature);
- a `_service` file fetches sources with `tar_scm`/`download_files` so OBS builds are reproducible;
- `*.spec` declares `BuildRequires`/`Requires`; OBS builds in a clean chroot (no network during the build);
- OBS project keys automatically sign the rpm/deb repositories; publishes `repodata`;
- it can also produce AppImage (OBS's AppImage build capability) and deb, but the deb quality is below the native Debian pipeline.

openSUSE package names are basically the same as Fedora's, but the availability of optional dependencies such as
`libappindicator` must be confirmed in the Leap/SLES repositories; the SLES default repositories are narrower and may
need Package Hub or self-built dependencies.

**Risks.**

1. OBS builds have no network, so Node/pnpm/Python assets must be vendored in advance or fetched via `_service`;
2. OBS arm64 worker resources are limited, so arm64 builds may queue for a long time;
3. SLES subscription/repository differences mean you cannot assume Leap's dependencies all exist on SLES;
4. maintaining the spec and `_service` is a second set of logic alongside the existing fpm pipeline.

**Update model.** OBS repository + `zypper up` gives the best experience; alternatively publish a single rpm only.

**Effort.** 3–5 person-days to set up the OBS project and first release; 1 person-day per release; maintaining both spec and fpm
increases long-term maintenance cost by roughly 30%.

---

### 3.4 Arch / Manjaro / EndeavourOS (pacman `pkg.tar.zst` / AUR)

**Target users.** Arch and its derivatives have a moderate total user base, but the highest density of developers, technical
opinion leaders, and users "willing to file issues/PRs"; AUR is a low-cost channel to reach them.

**Format and tooling.** `PKGBUILD` + `makepkg` produce `pkg.tar.zst`, installed by pacman. For the specification see
[Arch PKGBUILD](https://wiki.archlinux.org/title/PKGBUILD) and
[AUR](https://wiki.archlinux.org/title/Arch_User_Repository); for quality checks use
[namcap](https://wiki.archlinux.org/title/Namcap); for signing use `makepkg --sign` + pacman-key.
AUR hosts only the `PKGBUILD` and build scripts, not binaries; a `-bin` package can download the official AppImage/deb
and repackage it, but must declare the source and license.

**Key constraint: the system Electron cannot be used.** Arch does provide the `electron` meta package and a versioned
`electron44` (at the time of research `extra/electron 1:44-1`, depending on `electron44`), but the
[ArchWiki Electron package guidelines](https://wiki.archlinux.org/title/Electron_package_guidelines)
state explicitly: **applications that require `ELECTRON_RUN_AS_NODE=1` (such as VS Code) cannot use
`/usr/bin/electron*`**. This project's desktop shell starts the bundled Host exactly via `ELECTRON_RUN_AS_NODE`,
so the Electron runtime must ship with the package, installed to `/opt/deepseek-harness`, rather than depending on the
system Electron.

**Two approaches.**

1. **AUR `deepseek-harness-bin` (do this first)**: `source` points to the official AppImage or deb,
   `package()` unpacks it, installs to `/opt/deepseek-harness`, provides the `/usr/bin/deepseek-harness`
   wrapper, `.desktop`, and icons; `depends` lists system libraries such as GTK3/NSS. Pros: reuses verified artifacts,
   2–3 person-days; cons: not built from source, and the AUR community's acceptance of `-bin` depends on maintenance quality.
2. **Native `deepseek-harness`**: build the Electron app from source, with `electronDist` pointing at the bundled
   Electron 44 to avoid downloads; you must handle pnpm, Python, native modules, `app.asar`, and
   `chrome-sandbox` permissions. 5–8 person-days, and every Electron upgrade must be followed up.

**Notes on repackaging from the AppImage.**

- Keep the `usr/` structure after `--appimage-extract`; do not `strip` the Electron/Node binaries;
- `chrome-sandbox` needs root:root + 4755, otherwise the Chromium sandbox fails to start; the PKGBUILD
  can use `chmod 4755` under fakeroot, but the security implications must be documented in `.INSTALL`/the docs;
- the `Exec` in the AppImage's `.desktop` points to AppRun; after repackaging it must be changed to `/usr/bin/deepseek-harness`;
- `namcap` will warn about "undeclared dependencies", "file permissions", and "extraneous files"; each must be handled.

**Update model.** Updates via pacman/AUR helper; no in-app updates. Electron/GTK ABI changes in rolling distributions
may break old packages, requiring periodic rebuilds.

**Effort.** AUR `-bin` 2–3 person-days; native 5–8 person-days; entering the `extra` repository requires TU nomination and
source builds, which is unrealistic in the short term.

---

### 3.5 Alpine Linux (apk) — explicitly incompatible

**Conclusion: not supported in v1, and it is not a problem that "writing another APKBUILD" can solve.**

**Chain of causes.**

1. The official Electron prebuilt binaries are **glibc** builds; the Electron README explicitly says "prebuilt binaries
   are built on Ubuntu". Alpine uses **musl libc**, so the ELF interpreter and symbol versions do not match;
   executing directly yields `not found` or loader errors.
2. This project's artifact contains not only Electron but bundled Node 24, Python, `node-pty`, `sharp`, `koffi`,
   `sherpa-onnx`, and other native modules; most of them are glibc prebuilts (see the symbol scan in §4.2).
   `gcompat` covers only a small number of symbols and cannot reliably support the full Chromium/Electron runtime.
3. Alpine does have an `electron` package, but it is **rebuilt by Alpine itself from source with musl**:
   at the time of research `testing/x86_64/electron` was **42.11.18-r0**, depending on `so:libc.musl-x86_64.so.1`,
   see [Alpine package: electron](https://pkgs.alpinelinux.org/package/edge/testing/x86_64/electron).
   It is a different version from this project's Electron 44 and lives in `testing`, so it cannot be reused directly.
4. Even if Alpine's Electron 42 were forced to start, you would run into a series of mismatches around `ELECTRON_RUN_AS_NODE`,
   native module ABI, the bundled Node 24 runtime, and Python extensions.

**What it would take to support it anyway.**

- Build Electron 44 from source on Alpine (a Chromium build, tens of GB and hours, requiring many
  musl patches);
- Recompile all native modules and the Python runtime with musl;
- Maintain an independent `electron` version line and security updates;
- This becomes a separate product line rather than "adding one more package format".

**Recommendation.** State "Alpine is unsupported" clearly in the support matrix, with the reasons and alternatives (use the
dsh CLI in a container/remotely, or wait for an upstream musl build). Do not publish an `apk` package, to avoid users installing something that cannot start.

**Effort.** 15–30 person-days with a low success rate; not worth investing in.

---

### 3.6 Gentoo (ebuild)

**Target users.** A tiny but highly sticky group of source users; it is symbolic for people who want to "compile it themselves/control dependencies",
but it is low commercial priority.

**Current state.** As of this research, the Gentoo main tree has no generic `dev-util/electron` ebuild (neither the GitHub main-tree
directory nor the packages.gentoo.org search turned one up); Electron applications are usually handled by the application's own ebuild
unpacking the upstream binary/AppImage, or by using a bundled Electron. For the specification see
[Gentoo Devmanual: ebuild writing](https://devmanual.gentoo.org/ebuild-writing/);
for checks use [pkgcheck](https://wiki.gentoo.org/wiki/Pkgcheck).

**Viable approaches.**

1. **`deepseek-harness-bin` ebuild**: `SRC_URI` points to the official AppImage or deb,
   `src_unpack()` unpacks it, `src_install()` installs to `/opt/deepseek-harness`, and installs the wrapper,
   `.desktop`, and icons; `RDEPEND` lists `x11-libs/gtk+:3`, `dev-libs/nss`, `x11-libs/libXScrnSaver`, etc.
2. **Source ebuild**: build from source, depending on the system Node/pnpm/Python; high effort and tightly coupled to the upstream build chain.

**Risks.**

- Gentoo has many `USE` flag, `SLOT`, and `CHOST`/`ABI` combinations, so the test matrix explodes;
- prebuilt binaries conflict with Gentoo's "build from source" culture; such a package may only be able to enter an overlay (such as GURU),
  and entering the main tree requires maintainers and license/QA review;
- rolling upgrades change the Electron/GTK ABI, requiring continuous rebuilds.

**Update model.** `emerge -u`; no in-app updates.

**Effort.** 5–8 person-days (first overlay version); main-tree review is uncertain.

---

### 3.7 NixOS / Nix (nixpkgs)

**Target users.** Niche but growing fast, concentrated among developers, reproducible-build, and CI users; one derivation can
serve both NixOS and non-NixOS Nix users.

**Two derivation approaches.**

1. **Fast path: wrap the AppImage.** Use nixpkgs'
   [`appimageTools.wrapType2`](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-appimageTools)
   to extract and wrap it, together with `autoPatchelfHook` to fix the ELF interpreter and RPATH. Pros: usable within days;
   cons: a large closure, an extra layer in the startup path, hash changes on every update, and the Nix community generally does not accept
   "binary-only wrapping" as a formal nixpkgs package.
2. **Native path: `stdenv.mkDerivation` + unpacked official Electron.** Use electron-builder's
   `linux-unpacked` as `src`, handle all ELF files with `autoPatchelfHook`, and set
   `ELECTRON_RUN_AS_NODE`, `PATH`, `LD_LIBRARY_PATH` with `makeWrapper`; `buildInputs` lists GTK3/NSS, etc.
   This is the more maintainable long-term solution, but requires handling:
   - the setuid `chrome-sandbox` of the official Electron binary is unusable in the Nix store (the store is read-only
     and has no setuid); usually you switch to the user namespace sandbox, or add
     `--disable-setuid-sandbox` in the wrapper (security must be assessed);
   - the RPATH of native modules, the Python interpreter path, and the `pnpm` path all need patching;
   - building from source requires `fetchNpmDeps`/`buildNpmPackage` plus a pnpm offline cache,
     which significantly increases effort.

**Illustrative (structure only; not implemented, not tested):**

```nix
{ lib, fetchurl, appimageTools
, gtk3, nss, libnotify, libXScrnSaver, at-spi2-core, xdg-utils, libxtst, util-linux
}:

let
  pname = "deepseek-harness";
  version = "0.2.2-rc.1";
  src = fetchurl {
    url = "https://example.invalid/${pname}-${version}-x86_64.AppImage";
    hash = lib.fakeHash; # replace with the real SRI hash at release time
  };
  appimage = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;
  extraPkgs = pkgs: [ gtk3 nss libnotify libXScrnSaver at-spi2-core xdg-utils libxtst util-linux ];
  extraInstallCommands = ''
    install -Dm644 ${appimage}/usr/share/applications/*.desktop \
      $out/share/applications/${pname}.desktop
  '';
}
```

A truly native derivation should also replace `appimageTools.wrapType2` with
`stdenv.mkDerivation` + `autoPatchelfHook` + `makeWrapper`; do not copy the
`extraPkgs` list above directly as the complete dependency set.

**Verification.** `nix-build`, `nix flake check`, `nix run`, `nixpkgs-review`; on NixOS you also need
to verify in a real Wayland/X11 session.

**Risks.**

- nixpkgs' Electron version may not match this project's pinned 44.7.0; using the system Electron introduces
  `ELECTRON_RUN_AS_NODE`/ABI risk, so bundling is recommended;
- conflict between the read-only store and the Chromium sandbox;
- large closure size (Electron + Node + Python is on the order of 1 GB);
- entering the nixpkgs main tree requires maintainers, license, and build-reproducibility review, which takes a long time.

**Effort.** `appimageTools` wrapping 2–3 person-days; native derivation 5–10 person-days; entering nixpkgs
involves additional review time.

---

### 3.8 Snap (snapd / Snap Store)

**Target users.** Ubuntu ships snapd preinstalled, reaching all Ubuntu users; other distributions can install snapd too.
The Snap Store is a centralized store operated by Canonical, with review and automatic updates handled by the Store.

**Format and tooling.** `snapcraft.yaml` + `snapcraft pack`; check with `snapcraft lint`; publish with
`snapcraft upload`/`release`, signed on the Store side. There are two paths for Electron:

1. **electron-builder's `snap` target**: the Snapcraft documentation explicitly states that Electron supports snap,
   and electron-builder 22.7+ can run `electron-builder --linux snap` directly
   (see [Craft an Electron app](https://ubuntu.com/docs/snapcraft/9.2/how-to/integrations/craft-an-electron-app/)).
   This project's current target list only has AppImage/deb/rpm/flatpak, so adding `snap` is a configuration change.
2. **Write `snapcraft.yaml` yourself**: `plugin: dump` unpacks the existing deb/AppImage, `base: core24`,
   `confinement: strict` (or `classic`), `apps.<name>.command` points to the wrapper,
   `extensions: [gnome]` provides GTK themes/libraries, and `stage-packages` adds `libnss3`, `libxss1`, etc.

**Key constraint: the sandbox conflicts with the product's capabilities.** dsh is a local Agent and needs to:

- read and write the user's workspace (possibly outside `$HOME`);
- execute shell, `git`, `pnpm`, Python;
- access the network, local ports, and process information;
- install/run plugins (writing `~/.dsh`, project directories).

Under strict confinement, the `home` interface covers only non-hidden files, and `personal-files` requires declaring specific paths
and may be subject to Store review; interfaces such as `process-control` and `system-observe` increase the permission surface. If full local
capabilities are needed, usually the only option is to request **classic confinement**, which requires manual Store approval
and is not guaranteed. For "developer tool" applications, this is the biggest uncertainty of the Snap path.

**Runtime.** `base: core24` corresponds to the Ubuntu 24.04 userland (glibc 2.39), satisfying the §4.2 baseline;
Electron/Node/Python are still bundled with the app. `core24`'s support period aligns with Ubuntu 24.04, and `core26` needs to be planned
after Ubuntu 26.04 is released. See
[Snapcraft Bases](https://ubuntu.com/docs/snapcraft/9.2/reference/bases/).

**Update model.** snapd auto-refresh, published by channel (stable/candidate/edge); this is Snap's
biggest advantage over deb/rpm, but it also means automatic upgrades must be guaranteed not to break local data/plugins.

**Verification.** `snapcraft pack`, `snapcraft lint`; `snap install --dangerous` in LXD/VM
(there is no systemd/snapd in Docker, so it cannot be valid verification); check `snap connections`, actual file/
network access, and automatic refresh.

**Effort.** strict PoC 5–8 person-days; classic application and Store review 2–6 weeks, with an uncertain outcome.

---

### 3.9 Flatpak (Flathub / self-hosted OSTree)

**Target users.** Cross-distribution, sandboxed, graphical desktop users; Flathub is the de facto app store. It is strongly
attractive to users who "don't want to pollute the system and want automatic updates".

**Current state.** A single-file bundle has been produced:

- app id: `com.deepseek.harness`;
- x64: `org.freedesktop.Platform/x86_64/25.08`, `Sdk/x86_64/25.08`, `Electron2.BaseApp/x86_64/25.08`;
- arm64: `org.freedesktop.Platform/aarch64/25.08`, `Sdk/aarch64/25.08`, `Electron2.BaseApp/aarch64/25.08`;
- installation: `flatpak install --user ./deepseek-harness-*.flatpak`;
- launcher: `/app/lib/com.deepseek.harness/dsh-launch` (sets up `PATH` then calls `zypak-wrapper`);
- not submitted to Flathub, and there is no self-hosted OSTree repository.

**Runtime upgrade (x64/arm64 complete).** The Freedesktop SDK release table states explicitly that
`24.08` was released in 2024/08 and is supported until **2026/09, status EOL**; the currently supported versions are `25.08`
(until 2027/09) and `26.08` (until 2028/09). See
[Freedesktop SDK Release Timeline](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Releases).
Flathub's inclusion policy also explicitly does not accept EOL runtimes/baseapps. Therefore:

- continuing to produce bundles with 24.08 can only be an "internal/temporary" artifact and should not be a long-term release;
- `flatpak.runtimeVersion`/`baseVersion` have been upgraded to 25.08;
- the `org.electronjs.Electron2.BaseApp` 25.08 branch exists, and Electron 44 has been measured to start in that BaseApp;
- verification records are in [evidence/flatpak-2508-verify.txt](../evidence/flatpak-2508-verify.txt).

**Flathub's real bar.** Even with the runtime upgraded, Flathub is still not "upload the bundle":

- **Building from source is mandatory**; the manifest may not contain prebuilt binaries. The Electron BaseApp is allowed,
  but the app's own dsh/Node/Python artifacts cannot simply be put in. See
  [Flathub Requirements](https://docs.flathub.org/docs/for-app-authors/requirements).
- **No network during the build**; pnpm/npm/Python dependencies must be expanded in advance into sources with tools such as
  `flatpak-node-generator`; this project's runtime is large and dependency-heavy, so conversion cost is high.
- **Developer tool/IDE apps** face strict review and usually only accept submissions from upstream official projects; this project is a fork/derivative distribution,
  so brand, upstream relationship, and maintenance commitment must be settled first.
- **Minimal permissions**: static permissions such as `--filesystem=home` and `--share=network` will be scrutinized,
  while dsh's local Agent capabilities genuinely need broad file access. The two are structurally contradictory.

**Recommendation.** In the short term, position Flatpak as "self-built bundle / self-hosted OSTree repository" without promising Flathub;
in the medium term, if Flathub is required, start a separate project for "source-built manifest + permission model + AppStream metadata"
and do not mix it with the runtime upgrade.

**Signing and repositories.** `flatpak build-sign` signs commits, and `flatpak build-update-repo --gpg-sign`
signs the repository; clients use `flatpak remote-add --gpg-import`. A single-file bundle is not itself an update repository;
a `.flatpakrepo` or an OSTree repository must also be provided for automatic updates.

**Verification.** `flatpak-builder --repo=...`, `flatpak build-import-bundle`,
`flatpak-builder-lint`, `appstreamcli validate`; the GUI must be verified on a real host (inside Docker
bwrap seccomp is restricted; evidence in [evidence/flatpak-gui.txt](../evidence/flatpak-gui.txt)).

**Effort.** 2–4 person-days per release to maintain; 3–5 person-days for the runtime upgrade; 15–30 person-days to make it source-built for Flathub,
with an uncertain review outcome.

---

### 3.10 AppImage (cross-distribution)

**Target users.** Users who do not want to install package-manager entries and want "download and run"; developers, CI, and temporary trial scenarios.
AppImage needs no root and writes no system directories, making it the easiest format to distribute.

**Current state.** electron-builder already produces a type 2 AppImage, and both arm64/x64 have been launch-verified under Xvfb.
The file is about 349–354 MB, contains Electron/Node/Python, and mounts a squashfs at startup.

**Tooling and specifications.** See the [AppImage Packaging Guide](https://docs.appimage.org/packaging-guide/index.html).
Sign with `appimagetool --sign` (embedded GPG signature); update information with
`--updateinformation` + zsync, and clients can use AppImageUpdate; see
[Signing AppImages](https://docs.appimage.org/packaging-guide/optional/signatures.html) and
[Making AppImages updateable](https://docs.appimage.org/packaging-guide/optional/updates.html).

**Risks.**

1. **No automatic updates**: there is currently no zsync/update information; users must download new versions manually.
2. **Unsigned**: `appimagetool --sign` is not wired up; distributing the GPG public key is also a problem.
3. **Chromium sandbox and userns**: Ubuntu 23.10+ restricts unprivileged user namespaces by default;
   the `chrome-sandbox` inside the AppImage cannot be made setuid the way deb can, which may cause startup failure or force
   `--no-sandbox`. Verify on real Ubuntu 24.04 hardware and prefer a userns/sandbox-compatible solution;
   do not make `--no-sandbox` the distribution default.
4. **FUSE**: environments without FUSE need `--appimage-extract-and-run`; Docker testing works this way.
5. **Size**: a 350 MB download is unfriendly on networks in China; mirrors/resumable downloads are needed.

**Update model.** Manual download + optional zsync/AppImageUpdate; you could also check the version in-app and prompt a download,
but do not automatically replace the binary without signature verification.

**Effort.** 0.5–1 person-day per release; 1–2 person-days to wire up signing and zsync.

---

## 4. Key Technical Constraints

### 4.1 Electron / Chromium runtime dependencies (by family)

Electron's Linux runtime dependencies are not "just glibc"; the graphics stack, NSS, AT-SPI, tray, and input methods all
need system libraries. The current deb/rpm dependencies are auto-generated by electron-builder/fpm and are basically usable, but the package
names differ between families:

| Capability | Debian/Ubuntu package name | Fedora/RHEL package name | Arch package name (reference) |
|---|---|---|---|
| GTK3 | `libgtk-3-0` (`libgtk-3-0t64` on 24.04+) | `gtk3` | `gtk3` |
| NSS/NSPR | `libnss3` | `nss` | `nss` |
| Notifications | `libnotify4` | `libnotify` | `libnotify` |
| Screensaver/idle inhibition | `libxss1` | `libXScrnSaver` | `libxss` |
| AT-SPI accessibility | `libatspi2.0-0` (t64 variant) | `at-spi2-core` | `at-spi2-core` |
| XTest | `libxtst6` | `libXtst` | `libxtst` |
| UUID | `libuuid1` | `libuuid` | `util-linux-libs` |
| Opening links/files | `xdg-utils` | `xdg-utils` | `xdg-utils` |
| Tray (optional) | `libappindicator3-1` | `libappindicator-gtk3` | `libappindicator-gtk3` |
| Keyring (optional) | `libsecret-1-0` | `libsecret` | `libsecret` |

Notes:

- deb's `Depends` includes `libsecret-1-0`, while rpm's automatic dependencies do **not** include `libsecret`; if the app uses the
  system keyring on Fedora, `Requires: libsecret` must be added to the spec.
- `libappindicator` is a `Recommends` on Debian and has no weak dependency on rpm; tray functionality may be unavailable in some
  Fedora/GNOME environments.
- Wayland also needs `libxkbcommon`, `libwayland-client`, etc.; Electron 44's Wayland support
  should still be treated as "experimental", and the Flatpak documentation also recommends defaulting to X11/XWayland.

### 4.2 glibc baseline and artifact measurements

Electron's official Linux binaries are built on Ubuntu and **depend on glibc; musl is not supported**; see
[Electron v44.7.0 README](https://github.com/electron/electron/blob/v44.7.0/README.md).
This project's current artifacts are built in `node:24-bookworm` (Debian 12, glibc 2.36), but "the build machine's glibc"
is not the same as "the minimum runtime glibc". A symbol-version scan of the ELF files in the x64 deb yields:

| Component | Highest `GLIBC_*` symbol version | Meaning |
|---|---|---|
| Electron main binary | `GLIBC_2.25` | Electron itself can load on older glibc |
| Bundled Node 24 | `GLIBC_2.28` | Node runtime floor |
| `node-pty` | `GLIBC_2.28` | Terminal/PTY feature floor |
| `sharp` | `GLIBC_2.17` | Image processing floor |
| `koffi` | `GLIBC_2.17` | FFI floor |
| `sherpa-onnx` | `GLIBC_2.32` | Speech/ONNX feature floor |

Therefore **the actual floor for the whole bundle is the maximum, 2.32** (assuming `sherpa-onnx` gets loaded; even if it is
lazy-loaded, "may crash" should not be left to users). The scan is based on ELF `GLIBC_*` symbol strings and is a
heuristic floor, not a complete ABI analysis; you should still actually launch on the target glibc version before releasing. On that basis:

| Distribution | glibc | Recommendation |
|---|---|---|
| Debian 12 bookworm | 2.36 | ✅ Supported |
| Debian 13 trixie | 2.41 | ✅ Supported (t64 dependencies must be verified) |
| Ubuntu 22.04 | 2.35 | ✅ Supported |
| Ubuntu 24.04 | 2.39 | ✅ Supported (t64 dependencies must be verified) |
| Ubuntu 20.04 | 2.31 | ⚠️ Below 2.32, not promised |
| Debian 11 bullseye | 2.31 | ⚠️ Below 2.32, not promised |
| RHEL 9 / Rocky 9 / Alma 9 | 2.34 | ✅ Supported |
| RHEL 10 / Rocky 10 / Alma 10 | 2.39 | ✅ Supported |
| RHEL 8 / CentOS 8 | 2.28 | ⛔ Unsupported |
| Fedora 41/42/43 | ≥ 2.40 | ✅ Supported |
| openSUSE Leap 15.6 / SLES 15 SP6 | 2.38 | ✅ Supported |
| Arch / Tumbleweed | latest rolling | ✅ Supported |
| Alpine | musl | ⛔ Unsupported (see §3.5) |

Note: the table above is a preliminary judgment "by glibc version" and does not mean GUI acceptance has been completed on every distribution; before release
you still need to do install + launch tests on the target images. Ubuntu 24.04's t64 packages have been measured to provide the old names
(see §3.1), but for Debian 13/arm64 the actual result of `apt install ./...deb` should still be authoritative.

### 4.3 Flatpak runtime and Snap base core24

| Item | Current/recommended | Notes |
|---|---|---|
| Flatpak runtime | `org.freedesktop.Platform//25.08` (verified) | Upgraded from the EOL 24.08 branch; x64 and arm64 install/launch verified |
| Flatpak BaseApp | `org.electronjs.Electron2.BaseApp//25.08` | Provides the base libraries required by Electron plus zypak; the version must match the runtime |
| Flatpak SDK | `org.freedesktop.Sdk//25.08` | Build-time only; verified with the 25.08 bundles |
| Snap base | `core24` (Ubuntu 24.04, glibc 2.39) | Currently supported; plan `core26` after Ubuntu 26.04 |
| Snap build | `snapcraft` (LXD/VM) | No snapd/systemd inside Docker, so valid installation verification is impossible |

Flatpak's Electron packaging guidance is in
[Flatpak docs: Electron](https://docs.flatpak.org/en/latest/electron.html): Freedesktop
runtime + Electron BaseApp + zypak wrapper is the standard combination; the docs recommend defaulting to `--socket=x11`,
with Wayland left to the user via `--ozone-platform-hint=auto`. This project's patch sets
`useWaylandFlags: true`, which deviates from the official "X11 by default, Wayland experimental" recommendation; it is recommended to revert to the more conservative
default before Wayland on-hardware acceptance, or to explicitly label it experimental.

### 4.4 Arch: the system Electron is unusable

This is the easiest trap to fall into. The ArchWiki Electron guidelines state explicitly:

> Applications that require `ELECTRON_RUN_AS_NODE=1`, e.g. Visual Studio Code,
> cannot use `/usr/bin/electron*`.

This project's `apps/desktop` Host is started via `ELECTRON_RUN_AS_NODE`, therefore:

- **Do not** put `depends=('electron')` in the PKGBUILD and then have the wrapper call `/usr/bin/electron`;
- **You must** install the Electron 44 runtime with the package into `/opt/deepseek-harness`;
- only if the architecture changes in the future to "pure GUI, no RunAsNode needed" can the system Electron be considered, but that is
  a product architecture change, not a packaging optimization.

The same applies to any idea of "using the system Electron to reduce size": first confirm whether RunAsNode is needed and whether the native module
ABI matches.

### 4.5 Alpine: the hard incompatibility of musl and glibc

Emphasized once more, because this is the part most easily misjudged as "just add a package":

- official Electron is a glibc binary; Alpine is musl;
- `gcompat` is not a complete glibc compatibility layer; Electron/Chromium dynamic loading, symbol versions, NSS, and
  the sandbox may all fail;
- Alpine's `electron` package is **another build line** (a musl rebuild from source), version 42.11.18, located in
  `testing`, and does not match this project's Electron 44;
- this project also bundles glibc-based Node/Python/native modules, so replacing only Electron is not enough.

**Conclusion: Alpine is unsupported; do not publish an apk package.** If users need Alpine, recommend the dsh CLI
(if upstream provides one) or a containerized approach, not the desktop app.

### 4.6 Trade-offs for the Nix derivation

- **Wrapping the AppImage**: fastest, suitable for personal flake/overlay use; the downside is "wrapping a binary", which the Nix community
  generally does not accept into the nixpkgs main tree, and updates require changing the hash.
- **Native derivation**: start from `linux-unpacked`, handle ELF with `autoPatchelfHook`, and inject the environment with
  `makeWrapper`; more maintainable, but requires handling the setuid sandbox, RPATH, and Python paths.
- **Building from source**: `buildNpmPackage`/`fetchNpmDeps` + pnpm offline cache + Python/native modules,
  the most "Nix-native" approach, but the most work, and the compatibility of upstream build scripts with the Nix sandbox is unknown.

Recommendation: first do a PoC with `appimageTools.wrapType2` to verify GUI/Agent capabilities, then decide whether to invest in a native
derivation; do not aim for nixpkgs inclusion from the start.

### 4.7 "Repackaging from AppImage" vs "native Electron build"

| Dimension | Repackaging from AppImage/deb | Native Electron build |
|---|---|---|
| Effort | Low (2–5 person-days) | High (5–15 person-days) |
| Reuses verified artifacts | ✅ | ⚠️ Requires re-verification |
| Distribution review acceptance | AUR `-bin` OK; Gentoo/Nix main trees harder | Higher |
| Update/rebuild | Follows upstream artifacts | Follows source/dependencies |
| Size | Same as AppImage | Can be trimmed |
| Risk | Unpack paths, desktop files, setuid permissions | Build chain, native modules, Electron version pinning |

Recommendation: **for Tier 2/3, first validate demand with repackaging** (AUR `-bin`, Gentoo overlay, Nix wrapper),
and invest in native builds only after a channel proves a stable user base.

### 4.8 The structural conflict between sandboxes and product capabilities

dsh is a local Agent that needs to execute shell, read and write the workspace, start local services, and install plugins. Flatpak/Snap's
strong sandboxing inherently conflicts with the "least privilege" store policies:

- Flatpak: needs `--filesystem=home` (or even host) and `--share=network`; Flathub reviews broad permissions
  strictly, and developer tools may even be turned away outright.
- Snap: under strict, `home` excludes hidden files, and `personal-files` must be declared; full capabilities usually require classic,
  which needs Store approval.

Therefore, **deb/rpm/AppImage are the channels with the most complete functionality; Flatpak/Snap should be positioned as "restricted mode/trial"**,
with permission differences made explicit in the docs. Do not sacrifice core capabilities to get into a store, and do not silently degrade
in the store version.

### 4.9 Signing and updates: currently a blank

- the existing `SHA256SUMS` + test GPG signature only proves the mechanism works; it is **not a release signature**;
- there is no electron-updater Linux integration and no self-hosted update server;
- each channel's native update capability differs: APT/DNF/Zypper/pacman/apk/emerge/nix each have their own repository mechanisms;
  Flatpak has OSTree; Snap has Store refresh; AppImage has zsync.

Recommend dividing the work by channel rather than building a "universal updater":

| Channel | Update method | Signing |
|---|---|---|
| deb | Self-hosted APT repository | `Release.gpg` / `InRelease` |
| rpm | Self-hosted DNF repository | `repomd.xml.asc` + `rpmsign` |
| AppImage | Manual/byte-level zsync | Embedded GPG + `SHA256SUMS.asc` |
| Flatpak | Self-hosted OSTree or Flathub | OSTree commit + repo GPG |
| Snap | Store refresh | Store signing |
| Arch/AUR | pacman/AUR helper | `makepkg --sign` / PGP |
| Nix | Binary cache/flake | `nix sign-paths` / cache key |

---

## 5. Verification and CI Matrix

Principles:

1. **Structural checks** (metadata, dependencies, file permissions) are done in containers; fast and repeatable;
2. **Install + launch** must be done in target distribution images; the GUI uses Xvfb, but the sandbox behavior of Flatpak/Snap
   is unreliable in Docker and requires a VM/real host;
3. every format needs "negative checks": missing dependencies, wrong architecture, unsigned, and EOL runtime should be rejected;
4. all artifacts' SHA-256 go into `SHA256SUMS`, which is then signed with an offline GPG key at release time.

| Format | Suggested images | Key commands | Pass criteria | Notes |
|---|---|---|---|---|
| deb | `debian:12`, `debian:13`, `ubuntu:22.04`, `ubuntu:24.04` | `dpkg-deb -I`, `lintian --fail-on error`, `apt-get install -y ./pkg.deb`, `deepseek-harness --version` (or launch) | Dependencies resolve, install succeeds, Xvfb launch, no missing lib | t64 package names must be measured; set a `lintian` baseline first |
| rpm | `fedora:41`, `fedora:42`, `rockylinux:9`, `almalinux:9`, `opensuse/leap:15.6` | `rpm -qpi`, `rpm -qpR`, `rpmlint`, `dnf install -y ./pkg.rpm`, launch | Dependencies resolve, install succeeds, no fatal SELinux denial, launches | RHEL 8 explicitly untested/unsupported; openSUSE uses zypper |
| AppImage | `ubuntu:22.04`, `ubuntu:24.04`, `fedora:42`, `archlinux:base` | `chmod +x`, `./app --appimage-extract-and-run`, `--appimage-extract`, `ldd` checks | Executable, window launches, no missing lib | Use extract-and-run when FUSE is unavailable; verify userns restrictions separately |
| Flatpak | `ubuntu:24.04` + flatpak; real host/VM | `flatpak-builder --repo`, `flatpak build-import-bundle`, `flatpak install --user`, `flatpak run`, `flatpak-builder-lint`, `appstreamcli validate` | Installs, launches, permissions as expected, runtime not EOL | bwrap seccomp is restricted in Docker; GUI needs a real host |
| Snap | Ubuntu 24.04 VM/LXD (not Docker) | `snapcraft pack`, `snapcraft lint`, `snap install --dangerous`, `snap connections`, `snap run` | Installs, launches, file/network permissions as expected, refresh loses no data | Docker has no snapd/systemd and cannot be used for verification |
| Arch | `archlinux:base-devel` | `makepkg -si --noconfirm`, `namcap PKGBUILD`, `namcap *.pkg.tar.zst`, `pacman -Qip` | Builds, installs, launches, complete dependencies | System Electron unusable; mind setuid |
| Alpine | `alpine:edge` | `abuild -r`, `abuild-sign`, `apk add --allow-untrusted`, `ldd` | **Expected failure**: the glibc Electron cannot load | Only used to document "unsupported" evidence; never published |
| Gentoo | `gentoo/stage3` | `ebuild *.ebuild manifest`, `pkgcheck scan`, `emerge --ask` | Builds, installs, launches | Requires an overlay; main-tree review uncertain |
| Nix | `nixos/nix` | `nix-build`, `nix flake check`, `nix run`, `nixpkgs-review` | Builds, launches, no RPATH/interpreter errors | The read-only store and sandbox need special verification |
| OBS | OBS worker (remote) | `osc build`, `osc results`, `osc submitreq` | All repositories/architectures build successfully, repository signature verifiable | No network during builds; dependencies must be vendored |

Additional commands (local static checks):

```bash
# Syntax-check all shell scripts (does not modify code)
bash -n scripts/*.sh

# Verify existing artifacts
scripts/verify-artifacts.sh

# Release signing (requires a real release key)
DSHD_GPG_KEY=<release-fingerprint> scripts/sign-artifacts.sh
```

CI implementation suggestions:

- use a GitHub Actions matrix to run "install + Xvfb launch" for deb/rpm/AppImage;
- use `flatpak-builder` for Flatpak build/lint, and move the GUI to a self-hosted runner or manual acceptance;
- use an LXD/VM job for Snap; do not pretend to verify it in Docker;
- archive `SHA256SUMS`, per-format metadata output, and lint results to `evidence/` on every release;
- add a "refuse to release" check for EOL runtimes (24.08 was the historical baseline; 25.08 is current).

---

## 6. Layered Recommendations and Implementation Roadmap

### 6.1 Tier breakdown

| Tier | Formats / channels | Positioning | Rationale |
|---|---|---|---|
| **Tier 1 (delivered, continuously maintained)** | deb, rpm, AppImage, Flatpak bundle | Primary release channels | Produced and verified; covers Debian/Ubuntu, Fedora/RHEL, cross-distribution downloads, and sandboxed users; no new toolchain needed |
| **Tier 2 (fill the gaps first)** | Snap, Arch/AUR, openSUSE OBS | Incremental coverage and developer channels | Snap reaches users who have Ubuntu preinstalled; Arch influences developer reputation; OBS invests once to produce rpm/deb/AppImage and serve openSUSE/SLES |
| **Tier 3 (opportunistic/community-driven)** | Gentoo, NixOS; Alpine explicitly unsupported | Long tail and ecosystem completeness | Gentoo/Nix users are few but sticky, well suited to doing overlays/flakes first; Alpine is hard-blocked by musl, with a very poor return on investment |

**The Tier 1 maintenance focus is not "adding more formats" but completing release quality:**

1. real release GPG signing (`SHA256SUMS.asc`, deb/rpm signing);
2. an install+launch matrix on Debian 12/13, Ubuntu 22.04/24.04, Fedora 41/42, and Rocky 9;
3. keep Flatpak on a supported runtime (25.08 is verified), add an EOL-runtime guard, and decide "self-hosted repository vs Flathub";
4. define the glibc support baseline clearly and state it on the download page/in the docs;
5. assess Wayland/tray/input methods; do not use `--no-sandbox` to paper over sandbox problems.

### 6.2 Phased plan

**P0 (1–2 weeks): release hygiene and support matrix**

- produce real release signatures and verification instructions;
- run deb/rpm/AppImage install+launch on 4–6 target images;
- fix known issues such as t64 dependencies, rpm weak dependencies, and desktop files;
- do not regress to Flatpak 24.08; the verified 25.08 x64/arm64 bundles are the current baseline;
- state the "supported/unsupported" distribution list clearly in the README/download page.

**Exit criteria**: `SHA256SUMS.asc` verifies; the target matrix is all green; the docs no longer imply that Flatpak can go to Flathub.

**P1 (2–6 weeks): Tier 2 PoC**

- **Snap**: do a core24 PoC with electron-builder's `snap` target or a minimal `snapcraft.yaml`;
  start with strict and record which capabilities are unavailable; then assess whether a classic request is worthwhile.
- **Arch**: publish AUR `deepseek-harness-bin`, repackaged from the AppImage; get `namcap` to zero on fixable items;
  collect issues and verify the update cadence.
- **openSUSE OBS**: create a `home:` project with a spec + `_service`, produce an rpm and install it with zypper;
  verify OBS signing and arm64 workers.

**Exit criteria**: each of the three channels has one artifact that builds repeatably and installs and launches; a clear maintainer/cadence exists;
there is a written conclusion on Snap permissions (whether strict suffices, whether to request classic).

**P2 (6–12 weeks): deepen and choose**

- if the Snap demand holds up, pursue Store review/classic; otherwise downgrade to "not published";
- if the Arch user base holds up, assess a native PKGBUILD (not depending on the system Electron);
- if Flathub is a strategic goal, start a separate project for a source-built manifest, permission model, and AppStream metadata;
  otherwise position Flatpak as a self-hosted repository;
- a Nix flake (starting with `appimageTools` wrapping) as a community contribution, not blocking the main line.

**P3 (opportunistic)**:

- Gentoo overlay ebuild;
- re-evaluate Alpine only if "upstream provides a musl Electron build";
- nomination of community-maintained AUR/Nix/Gentoo packages into official repositories.

### 6.3 Things not to do

- ❌ Publish an apk package for Alpine (it installs but does not run, damaging trust);
- ❌ Replace the bundled runtime with Arch's system Electron (`ELECTRON_RUN_AS_NODE` simply will not hold);
- ❌ Upload the Flatpak bundle directly to Flathub (prebuilt binaries + EOL runtime, guaranteed rejection);
- ❌ Do automatic updates without release signing/update verification;
- ❌ Duplicate multiple build pipelines "to support more formats", causing version drift.

---

## 7. Risk Register

| # | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| 1 | EOL Flatpak runtime regression | Missing security updates, Flathub rejection, impossible to install in future | Medium | 25.08 x64/arm64 are verified; add a CI guard that refuses 24.08 and re-check the Electron BaseApp branch before each runtime upgrade |
| 2 | Alpine musl incompatibility | Users cannot start the app after installing | Certain | State explicitly that it is unsupported; document the reasons and alternatives |
| 3 | Misuse of Arch's system Electron | Host cannot start | Medium | Bundle Electron in the package; PKGBUILD must not depend on `electron` |
| 4 | RHEL 8 / Debian 11 / Ubuntu 20.04 glibc too old | Launch/speech module crashes | High | Declare glibc ≥ 2.32; mark the support matrix on the download page |
| 5 | Ubuntu 24.04 t64 dependencies unsatisfied | `apt install` fails | Medium | Measure on a noble image; change `Depends` or add alternative dependencies if needed |
| 6 | Insufficient Snap strict permissions | Core functionality unavailable | High | Enumerate gaps in a PoC first; request classic if needed; otherwise do not publish |
| 7 | Flathub source build/permission review | Cannot list; wasted investment | High | Self-hosted repository first; treat Flathub as a separate project, not tied to management commitments |
| 8 | No release signing/updates | Supply-chain risk; users cannot upgrade safely | High | Complete GPG signing in P0; wire up native repository updates per channel |
| 9 | AppImage sandbox failure on Ubuntu 24.04 | Launch failure or forced `--no-sandbox` | Medium | Verify userns on real hardware; offer deb as an alternative; do not disable the sandbox by default |
| 10 | Electron version pinned to 44.7.0 | Cost of following security updates/ABI | Medium | Establish an Electron upgrade checklist; re-verify every format |
| 11 | Flatpak Wayland default deviates from official guidance | Unstable Wayland sessions | Medium | Default to X11/XWayland; label Wayland experimental and do on-hardware acceptance |
| 12 | rpm lacks `libsecret`/`libappindicator` weak dependencies | Missing keyring/tray functionality | Medium | Add `Requires`/`Recommends` in the spec; explain in the docs |

---

## 8. Reference Links

### General / Electron

- [Electron v44.7.0 README (platform support and prebuilt binaries)](https://github.com/electron/electron/blob/v44.7.0/README.md)
- [Electron release timelines](https://www.electronjs.org/docs/latest/tutorial/electron-timelines)
- [Electron installation/mirrors](https://www.electronjs.org/docs/latest/tutorial/installation)

### Debian / Ubuntu

- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)
- [Ubuntu Packaging Guide](https://packaging.ubuntu.com/html/)
- [Lintian](https://lintian.debian.org/)
- [Lintian manpage](https://manpages.debian.org/testing/lintian/lintian.1.en.html)

### Fedora / RHEL / openSUSE

- [Fedora Packaging Guidelines](https://docs.fedoraproject.org/en-US/packaging-guidelines/)
- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/)
- [rpmlint](https://github.com/rpm-software-management/rpmlint)
- [Open Build Service User Guide](https://openbuildservice.org/help/manuals/obs-user-guide/)

### Arch

- [Arch PKGBUILD](https://wiki.archlinux.org/title/PKGBUILD)
- [Arch User Repository (AUR)](https://wiki.archlinux.org/title/Arch_User_Repository)
- [ArchWiki: Electron package guidelines](https://wiki.archlinux.org/title/Electron_package_guidelines)
- [namcap](https://wiki.archlinux.org/title/Namcap)
- [Arch package: electron](https://archlinux.org/packages/extra/x86_64/electron/)

### Alpine / Gentoo

- [Alpine APKBUILD Reference](https://wiki.alpinelinux.org/wiki/APKBUILD_Reference)
- [Alpine abuild](https://wiki.alpinelinux.org/wiki/Abuild)
- [Alpine package: electron (testing, musl)](https://pkgs.alpinelinux.org/package/edge/testing/x86_64/electron)
- [Gentoo Devmanual: ebuild writing](https://devmanual.gentoo.org/ebuild-writing/)
- [Gentoo pkgcheck](https://wiki.gentoo.org/wiki/Pkgcheck)

### Nix / NixOS

- [Nixpkgs manual: AppImage tools](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-appimageTools)
- [Nixpkgs manual: Electron](https://nixos.org/manual/nixpkgs/stable/#electron)
- [Nixpkgs package search](https://search.nixos.org/packages)

### Snap

- [Snapcraft documentation](https://documentation.ubuntu.com/snapcraft/stable/)
- [Snapcraft: Bases](https://ubuntu.com/docs/snapcraft/9.2/reference/bases/)
- [Snapcraft: Craft an Electron app](https://ubuntu.com/docs/snapcraft/9.2/how-to/integrations/craft-an-electron-app/)
- [Snapcraft: lint command](https://ubuntu.com/docs/snapcraft/9.2/reference/commands/lint/)
- [Snapcraft: Electron apps](https://snapcraft.io/docs/electron-apps)

### Flatpak / AppImage

- [Flatpak docs: Electron](https://docs.flatpak.org/en/latest/electron.html)
- [Flatpak docs: single-file bundles](https://docs.flatpak.org/en/latest/single-file-bundles.html)
- [Flatpak docs: available runtimes](https://docs.flatpak.org/en/latest/available-runtimes.html)
- [Flathub: requirements](https://docs.flathub.org/docs/for-app-authors/requirements)
- [Flathub: runtimes](https://docs.flathub.org/docs/for-app-authors/runtimes)
- [Flathub: flatpak-builder-lint](https://docs.flathub.org/docs/for-app-authors/linter)
- [Freedesktop SDK release timeline (24.08 EOL)](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Releases)
- [AppImage packaging guide](https://docs.appimage.org/packaging-guide/index.html)
- [AppImage: signing](https://docs.appimage.org/packaging-guide/optional/signatures.html)
- [AppImage: updates](https://docs.appimage.org/packaging-guide/optional/updates.html)

### In-repository documentation

- [architecture.md](architecture.md)
- [release.md](release.md)
- [testing.md](testing.md)
- [research/official-desktop-audit.md](research/official-desktop-audit.md)
- [../README.md](../README.md)
