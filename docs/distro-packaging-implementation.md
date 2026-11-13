# Linux Distribution Packaging Implementation Status

> Status: **implemented + statically verified (2026-11-10)**. This document records only the
> distribution channel files newly added under `packaging/`, the reproducible commands, and the
> boundaries that were actually verified. **The application was not rebuilt**; every channel reuses
> the existing AppImage or RPM in `dist/linux-x64` / `dist/linux-arm64`.
>
> For research background, format trade-offs, and CI suggestions, see
> [distro-packages.md](distro-packages.md); this document only answers
> "which files have been written, which commands have been run, and which conclusions remain
> unproven".

---

## 1. Overview

| Channel | New files | Build command (target environment) | Current status | Evidence / boundaries |
|---|---|---|---|---|
| Arch / AUR `-bin` | `packaging/aur/PKGBUILD`, `packaging/aur/.SRCINFO` | `cd packaging/aur && makepkg -si` | **Build + `pacman -Udd` install + Xvfb GUI launch verified (x86_64)**; aarch64 not built | Generated `deepseek-harness-bin-0.2.2_rc.1-1-x86_64.pkg.tar.zst` in an `archlinux:base-devel` (amd64) container; `.SRCINFO` exactly matches `makepkg --printsrcinfo`; sha256 verification passed; `chrome-sandbox` is `4755 root:root`. See §3.1 |
| Snap | `packaging/snap/snapcraft.yaml`, `packaging/snap/icon.png` | `cd packaging/snap && snapcraft pack` | **`.snap` manually built (squashfs)**; not `snap install`ed / `snap run` | No `snapcraft` on this machine (no longer in the Ubuntu 24.04 repositories, PyPI only has 4.8.1, the official image cannot be pulled); a 297 MB `.snap` was generated from the installed AUR payload + `mksquashfs`, and `unsquashfs -l` verified `meta/snap.yaml`, the wrapper, the desktop file, and the `/opt` payload. See `evidence/snap-build.txt`; for the strict confinement gaps see §3.2 |
| openSUSE OBS | `packaging/obs/deepseek-harness.spec`, `packaging/obs/_service` | `osc service ra && osc build openSUSE_Tumbleweed x86_64` | **The spec has produced a package via local `rpmbuild` (x86_64)**; not built in OBS/osc, not installed | Binary repackaging of the spec with Arch `rpm-tools` + `--nodeps`, producing a 273 MB `deepseek-harness-0.2.2~rc1-0.x86_64.rpm`; OBS server-side build and signing remain unverified. See `evidence/obs-build.txt`; details in §3.3 |
| Nix / NixOS | `packaging/nix/package.nix`, `packaging/nix/flake.nix` | `cd packaging/nix && nix build .#default`; `nix run .#` | **Static verification only**; not parsed, not built | No `nix` on this machine; uses `appimageTools.extractType2` + `autoPatchelfHook`; see §3.4 |
| Gentoo | `packaging/gentoo/deepseek-harness-bin-0.2.2_rc1-r3.ebuild` | `ebuild ... manifest && emerge ...` (overlay/GURU) | **Verified on Gentoo 2.18 / Portage 3.0.83**: `pkgcheck scan` clean, `fetch`, `clean unpack prepare install`, `emerge -pv`, and Wayland launch | A prebuilt AppImage conflicts with main-tree culture; overlay/GURU is the realistic entry point; see §3.5 |
| Alpine | None added | — | **Explicitly not provided** | musl is incompatible with Electron's official glibc binaries; rationale in §3.5/§4.5 of the research document |

Status legend:

- **Package build verified**: the channel's packaging command was actually executed and the artifact inspected; this does not equal GUI launch/install acceptance.
- **Static verification only**: the files parse and the key fields/paths exist, but the channel's native build tooling was never run.
- **Not verified**: no build or install has ever been executed; usability cannot be claimed.

---

## 2. Common design

### 2.1 Why repackaging rather than source builds

The existing `dist/` artifacts already bundle Electron 44, Node 24, Python, pnpm, and native
modules; the desktop shell's Host is launched via `ELECTRON_RUN_AS_NODE`, so it cannot be swapped
for the distribution's `electron` (ArchWiki documents explicit restrictions on this). All channels
in this batch use **binary repackaging/wrapping**:

- AUR, OBS, Gentoo: unpack the AppImage/RPM and install to `/opt/deepseek-harness`;
- Snap: `dump` plugin + `override-build` unpacks the AppImage into `$CRAFT_PART_INSTALL/opt`;
- Nix: `appimageTools.extractType2` unpacks, `autoPatchelfHook` fixes the ELF files.

### 2.2 Unified layout

```text
/opt/deepseek-harness/            # unpacked AppDir (Electron, resources, usr/lib)
/usr/bin/deepseek-harness         # shell wrapper: sets APPDIR/PATH/LD_LIBRARY_PATH then execs
/usr/share/applications/deepseek-harness.desktop
/usr/share/icons/hicolor/1024x1024/apps/deepseek-harness.png
```

Shared caveats:

1. **Do not strip** Electron/Node/Python or `.node` native modules; AUR uses `options=('!strip')`,
   Gentoo uses `RESTRICT="strip"` + `QA_PREBUILT="*"`.
2. **`chrome-sandbox` permissions**: AUR/OBS/Gentoo set `4755` after installation by root; the
   read-only mounts of Snap/Nix cannot use setuid, so the wrapper forces
   `--disable-setuid-sandbox` and relies on unprivileged user namespaces. If the target kernel
   disables userns, Snap provides an explicit escape hatch via `DSHD_SNAP_NO_SANDBOX=1`;
   **it is not a default**.
3. **The desktop file's `Exec=` must point to `/usr/bin/deepseek-harness`**, not the `AppRun`
   from inside the AppImage.
4. The upstream AppImage/RPM is still **unsigned**; these channel files do not change the signing
   status.

### 2.3 Versions and checksums

| Channel | Version representation | Verification |
|---|---|---|
| AUR | `0.2.2_rc.1` (`_` avoids confusion with the `-` in `pkgrel`) | Defaults to GitHub Releases, sha256 is the value of the current `dist` artifact; can be overridden with `DSHD_*` |
| Snap | `0.2.2-rc.1` | `source-checksum: sha256/<hex>` |
| OBS | `0.2.2~rc1` (RPM `Version`) | `verify_file` in `_service` pins the sha256 |
| Nix | `0.2.2-rc.1` | `fetchurl` SRI hash |
| Gentoo | `0.2.2_rc1-r3` | `Manifest` committed for x86_64 and aarch64 |

The AUR GitHub Releases URL has the form:

```text
https://github.com/deepseek-ai/deepseek-harness/releases/download/v0.2.2-rc.1/
  deepseek-harness-0.2.2-rc.1-linux-x86_64-unsigned.AppImage
  deepseek-harness-0.2.2-rc.1-linux-arm64-unsigned.AppImage
```

If upstream actually publishes elsewhere, only `_release_url` / `source_*` at the top of the
`PKGBUILD` need to change, or the local override variables can be used. **The existence of the
repository URL was not treated as a verified fact**: local builds used the `dist/` artifacts.

---

## 3. Per-channel details

### 3.1 Arch / AUR: `deepseek-harness-bin`

**Files.** `packaging/aur/PKGBUILD`, `packaging/aur/.SRCINFO`.

**Package behavior.**

- `arch=('x86_64' 'aarch64')`;
- `source_x86_64` / `source_aarch64` default to GitHub Releases; `DSHD_APPIMAGE_X86_64` /
  `DSHD_APPIMAGE_AARCH64` can switch them to local files (offline builds);
- `DSHD_PKGVER`, `DSHD_PKGREL`, `DSHD_UPSTREAM_VER` adjust the version;
- `DSHD_APPDIR` skips executing the AppImage and uses an already-unpacked AppDir directly (for
  build hosts that cannot execute the AppImage runtime; source file checksums are still verified);
- `prepare()` runs `AppImage --appimage-extract`, `package()` installs to
  `/opt/deepseek-harness`, generating the wrapper, desktop file, and 1024px icon;
- `chrome-sandbox` is set to `4755`; `options=('!strip' '!debug')`;
- no dependency on the system `electron`.

**Local development commands (normal network access):**

```bash
cd packaging/aur
makepkg --printsrcinfo > .SRCINFO   # after changing the version
makepkg -si
```

**Offline/local artifacts:**

```bash
cd packaging/aur
DSHD_APPIMAGE_X86_64="$PWD/../../dist/linux-x64/deepseek-harness-0.2.2-rc.1-linux-x86_64-unsigned.AppImage" \
  makepkg -si --skipinteg
```

**Actual verification (2026-11-10).**

Environment: Docker `archlinux:base-devel`, `--platform linux/amd64`, image from
`docker.m.daocloud.io/library/archlinux:base-devel` (direct Docker Hub access was unavailable).
Because this Apple Silicon host reports
`cannot execute binary file: Exec format error` / `ELF file ABI version invalid` for the x86_64
AppImage runtime, verification first unpacked it on the host with `7z`, then built via
`DSHD_APPDIR=/appdir`. **This is not a substitute for the PKGBUILD's normal path**; on a normal
x86_64 Linux the `AppImage --appimage-extract` path is still used.

Key commands:

```bash
docker run --rm --platform linux/amd64 \
  -v "$PWD:/work:ro" -v "/tmp/dshd-appdir:/appdir:ro" \
  docker.m.daocloud.io/library/archlinux:base-devel bash -lc '
    useradd -m builder
    mkdir -p /home/builder/aur
    cp /work/packaging/aur/PKGBUILD /home/builder/aur/
    cp /work/dist/linux-x64/deepseek-harness-0.2.2-rc.1-linux-x86_64-unsigned.AppImage /home/builder/aur/
    chown -R builder:builder /home/builder/aur
    cd /home/builder/aur
    runuser -u builder -- env \
      DSHD_APPIMAGE_X86_64=/home/builder/aur/deepseek-harness-0.2.2-rc.1-linux-x86_64-unsigned.AppImage \
      DSHD_APPDIR=/appdir \
      makepkg --noconfirm --nodeps --skipinteg
  '
```

Actual result (`--build aur` script, `DSHD_APPDIR=/appdir`):

```text
[PASS] .SRCINFO matches makepkg --printsrcinfo
[PASS] local x86_64 AppImage matches PKGBUILD sha256
[PASS] local aarch64 AppImage matches PKGBUILD sha256
[PASS] AUR package built: .../deepseek-harness-bin-0.2.2_rc.1-1-x86_64.pkg.tar.zst
-> aur      lint=PASS build=BUILT verified=BUILD-ONLY
```

Package (from the same verification's `pacman -Qip`/`bsdtar` checks):

```text
deepseek-harness-bin-0.2.2_rc.1-1-x86_64.pkg.tar.zst   338.07 MiB
Installed Size: 1090.75 MiB
```

`diff -u` between `.SRCINFO` and `makepkg --printsrcinfo` in the container produces no output. Key
files in the package:

```text
-rwsr-xr-x root root  15232  opt/deepseek-harness/chrome-sandbox
-rwxr-xr-x root root  ...    opt/deepseek-harness/deepseek-harness
-rwxr-xr-x root root  487    usr/bin/deepseek-harness
-rw-r--r-- root root  291    usr/share/applications/deepseek-harness.desktop
```

**Verified / not verified.**

- ✅ x86_64 package build, `.SRCINFO` consistency, source sha256, wrapper/desktop/icon
  installation, `chrome-sandbox` setuid bit.
- ✅ `pacman -Udd` installation was executed in the same Arch container:
  `pacman -Q deepseek-harness-bin` returns `0.2.2_rc.1-1`, and `/usr/bin/deepseek-harness`,
  `/opt/deepseek-harness/chrome-sandbox` (`4755 root:root`) exist.
- ✅ After installing the dependencies `nss gtk3 pango cairo alsa-lib mesa libxkbcommon libcups
  libxss at-spi2-core libxtst libsecret xdg-utils libx11 libxcomposite libxdamage libxrandr
  expat zlib libnotify xorg-server-xvfb`, a real launch inside Xvfb :99 returned a `dsh-app://`
  page from `--remote-debugging-port=9222`; screenshot
  `evidence/linux-arch-aur-start.png`.
- ✅ `package()` now applies `chmod 755` to `deepseek-harness`, `chrome_crashpad_handler`, and
  `resources/runtime/**/bin/*`, fixing the loss of executable bits when `DSHD_APPDIR` comes from a
  non-Linux unpacker; after the fix, reinstall and launch passed.
- ❌ `namcap` was not run; for aarch64 only the source file hashes were verified, and it was not
  built on arm64 Arch.
- ❌ The AppImage runtime's normal unpack path did not execute successfully on this host (emulator
  limitation), so "`--appimage-extract` works on Arch" remains a reasonable inference, not local
  evidence.

**Limitations.**

- AUR is an unofficial repository; `-bin` packages require maintainers to keep up with upstream
  artifacts;
- upstream is unsigned, and AUR does not host binaries;
- Arch rolling upgrades may change the GTK/NSS ABI; rebuilds must follow upstream;
- `depends` was assembled from the existing deb/rpm and common Arch package names; `namcap`/a real
  install may still require adjustments;
- setuid `chrome-sandbox` has security implications; if relying on userns only, consider changing
  to `0755` and accepting an explicit message when launch fails.

---

### 3.2 Snap: `packaging/snap/snapcraft.yaml`

**Files.** `snapcraft.yaml` + `icon.png` (512×512, from the existing AppImage icon).

**Design.**

- `base: core24`; `confinement: strict`; `grade: stable`;
- single amd64 platform; `plugin: dump` fetches the x86_64 AppImage from GitHub Releases, and
  `override-build` unpacks it with `--appimage-extract` into `$CRAFT_PART_INSTALL/opt/deepseek-harness`;
- `apps.deepseek-harness.command: bin/deepseek-harness`, the wrapper sets the `$SNAP` path;
- `desktop:` points at the generated desktop file, `Icon=${SNAP}/...`;
- `extensions: [gnome]` provides the GTK/desktop/wayland/x11 runtime connections;
- additional `plugs`: `home`, `network`, `network-bind`, `process-control`, `system-observe`,
  `cups-control`, `dot-dsh` (`personal-files` writing `$HOME/.dsh`).

**Build commands.**

```bash
cd packaging/snap
snapcraft pack
snap install --dangerous ./deepseek-harness_0.2.2-rc.1_amd64.snap
snap run deepseek-harness
```

**Verified.**

- ✅ Ruby YAML parsing passes;
- ✅ structural checks: `base: core24`, `confinement: strict`, wrapper command, desktop, sha256,
  `personal-files` are all present;
- ❌ no `snapcraft pack` (not installed on this machine), no `snap install`, no Store upload.

**Explicit capability limitations (strict).**

1. **`$HOME` is remapped by snapd** to the snap's per-user data directory; the real home is only
   accessible through the `home` interface, which excludes hidden files by default. `~/.dsh` is
   declared via `personal-files`, but that interface requires Store review and only covers the
   declared paths.
2. **The host toolchain is not visible**: dsh needs to execute a shell, `git`, `pnpm`, Python, and
   access the workspace. A strict snap's AppArmor generally does not allow executing arbitrary
   programs under the host `/usr/bin`; bundled pnpm/Python work, but external tools/plugin
   installation will be restricted.
3. **Local port/process observation** depends on `network-bind`, `process-control`,
   `system-observe`, some of which are manually connected or reviewed interfaces.
4. **sandbox**: snap mounts read-only, so a setuid `chrome-sandbox` is unavailable; the wrapper
   forces `--disable-setuid-sandbox` and requires userns. If the target system forbids
   unprivileged userns, the only option is to explicitly set `DSHD_SNAP_NO_SANDBOX=1` (not
   recommended, and never enabled by default).
5. **arm64** is not covered by this yaml; a separate source URL/remote build is required.
6. For full local Agent capability, the realistic route is **classic confinement**, but that
   requires manual Snap Store approval and cannot be assumed.

**Conclusion.** This yaml is a reviewable strict PoC, not a commitment that it is "publishable to
the Snap Store".

---

### 3.3 openSUSE OBS: `deepseek-harness.spec` + `_service`

**Strategy: binary repackaging, not a source build.** `_service` uses `download_url` to fetch the
x86_64/aarch64 RPM produced by electron-builder and `verify_file` to pin the sha256; the spec
unpacks with `rpm2cpio | cpio`, installs to `/opt/deepseek-harness`, and OBS handles re-signing the
repository.

**Files.**

- `packaging/obs/_service`: two `download_url` + two `verify_file`;
- `packaging/obs/deepseek-harness.spec`:
  - `ExclusiveArch: x86_64 aarch64`, no `BuildArch: noarch`;
  - `Version: 0.2.2~rc1`, `%global upstream_ver 0.2.2-rc.1`;
  - `%prep` selects `SOURCE0`/`SOURCE1` per `%ifarch`;
  - `%install` generates the wrapper, desktop file (`desktop-file-validate`), and icon;
  - `%files` marks `chrome-sandbox` with `%attr(4755,root,root)`;
  - `%post`/`%postun` update the desktop/mime/icon caches.

**Commands.**

```bash
# locally (requires osc + an OBS project)
osc service ra
osc build openSUSE_Tumbleweed x86_64
osc results
```

**Verified.**

- ✅ `_service` parses with Python `xml.etree`; service count/filenames/64-bit checksum checks
  pass;
- ✅ spec text checks: `%prep`/`%install`/`%files`, dual architecture, `rpm2cpio`,
  `desktop-file-validate`, `%attr(4755...)` are present;
- ✅ A local `rpmbuild` with Arch `rpm-tools` and `--nodeps` buildrequires produced a 273 MB
  `deepseek-harness-0.2.2~rc1-0.x86_64.rpm`; see `evidence/obs-build.txt`;
- ❌ no `osc build`, no OBS service build, and no `zypper install` on Leap/Tumbleweed.

**Limitations.**

- the upstream RPM is unsigned; OBS only signs the repository metadata/packages it produces
  itself;
- `_service` requires OBS-side access to GitHub Releases; the build phase itself has no network,
  so downloads must complete during the service phase;
- dependency names follow common openSUSE package names (`mozilla-nss`, `libXss1`, etc.); repository
  differences on Leap/SLES still need a real build to confirm;
- binary repackaging may trigger OBS/distribution review of "prebuilt binaries"; this is not an
  official openSUSE source package;
- no `%check`; no SELinux/AppArmor policy.

---

### 3.4 Nix / NixOS: `package.nix` + `flake.nix`

**Files.**

- `packaging/nix/package.nix`:
  - `fetchurl` selects the x86_64/arm64 AppImage via `stdenv.hostPlatform.system`, SRI hashes
    filled in;
  - `appimageTools.extractType2` unpacks;
  - `stdenv.mkDerivation` + `autoPatchelfHook` fix the ELF interpreter/RPATH;
  - `buildInputs` provides GTK3/NSS/AT-SPI/X11 and so on;
  - `makeWrapper` generates `$out/bin/deepseek-harness`, setting `APPDIR`, `LD_LIBRARY_PATH`,
    `XDG_DATA_DIRS`, `GSETTINGS_SCHEMA_DIR`, and adding `--disable-setuid-sandbox`;
  - `makeDesktopItem` + `copyDesktopItems` install the desktop file.
- `packaging/nix/flake.nix`: `packages.<system>.default` and `apps.<system>.default`, supporting
  `nix run .#`.

**Commands.**

```bash
cd packaging/nix
nix build .#default
nix run .#
```

**Verified.**

- ✅ text checks: `appimageTools.extractType2`, `autoPatchelfHook`, `makeWrapper`, SRI hashes, and
  the flake's `packages`/`apps` outputs are all present;
- ❌ there is no `nix`/`nix-instantiate` on this machine; not parsed, not built, no `nix run`.

**Limitations.**

- this is binary wrapping, not a source derivation acceptable to the nixpkgs main tree; the closure
  is large (Electron + Node + Python);
- `autoPatchelfHook` will try to process the entire Python/native module tree, and
  `autoPatchelfIgnoreMissingDeps = true` may mask missing optional dependencies; not verified on a
  real derivation;
- the Nix store is read-only, so a setuid `chrome-sandbox` is unavailable; relies on unprivileged
  userns;
- there is no `flake.lock`, so the first build resolves `nixos-unstable` and is not
  byte-for-byte reproducible;
- no `nixpkgs-review`/maintainer review.

---

### 3.5 Gentoo: `deepseek-harness-bin-0.2.2_rc1-r3.ebuild`

**Files.** `packaging/gentoo/deepseek-harness-bin-0.2.2_rc1-r3.ebuild` and
`packaging/gentoo/Manifest`.

**Behavior.**

- `EAPI=8`; `KEYWORDS="~amd64 ~arm64"`; dual architecture;
- upstream `0.2.2-rc.1.3` maps to Gentoo `0.2.2_rc1-r3`; Gentoo cannot encode
  the fourth numeric field after `_rc1`, so `-r3` is the packaging revision;
- `SRC_URI` points at the DSHD GitHub Release (not the upstream
  `deepseek-ai/deepseek-harness` release, which has no Linux assets), uses
  `${PF}` for the distfile names, and renames the AppImage with `->`;
- `S="${WORKDIR}"` so Portage finds the extracted source directory;
- `src_unpack()` runs `AppImage --appimage-extract`;
- `src_install()` installs to `/opt/deepseek-harness`, generates the wrapper/desktop file,
  `doicon -s 1024`;
- `fowners root:root` + `fperms 4755` set `chrome-sandbox`;
- `RDEPEND` uses `app-crypt/libsecret` (not `dev-libs/libsecret`);
- `RESTRICT="strip"`, `QA_PREBUILT="*"`;
- `pkg_postinst`/`pkg_postrm` call the xdg-utils eclass to update the desktop/icon/mime caches.

**Commands (overlay).**

```bash
mkdir -p /var/db/repos/dshd/app-misc/deepseek-harness-bin
cp packaging/gentoo/deepseek-harness-bin-0.2.2_rc1-r3.ebuild \
  packaging/gentoo/Manifest \
  /var/db/repos/dshd/app-misc/deepseek-harness-bin/
cd /var/db/repos/dshd/app-misc/deepseek-harness-bin
# Regenerate after changing the ebuild or version:
# ebuild deepseek-harness-bin-0.2.2_rc1-r3.ebuild manifest
emerge -av dev-util/pkgcheck
pkgcheck scan
emerge -av app-misc/deepseek-harness-bin
```

The committed `Manifest` contains both the x86_64 and aarch64 AppImages and
their SHA-512/BLAKE2B values. Manifest generation downloads both conditional
sources, which is normal for a multiarch ebuild; a user `emerge` fetches only the
AppImage selected by the current architecture.

**Verified.**

- ✅ `bash -n` passes;
- ✅ source URL returns HTTP 302 to the DSHD release asset;
- ✅ Manifest includes the EBUILD entry and both DIST entries; sizes and SHA-512/BLAKE2B match the published AppImages;
- ✅ structural checks: `EAPI=8`, `RESTRICT="strip"`, `QA_PREBUILT`, `S="${WORKDIR}"`,
  `fperms 4755`, `doicon -s 1024` are present;
- ✅ `pkgcheck scan` clean on Gentoo 2.18 / pkgcheck 0.10.49;
- ✅ `ebuild … fetch`, `clean unpack prepare install`, `emerge -pv`, and a
  Wayland launch passed on the final revision.

**Limitations.**

- a prebuilt AppImage conflicts with Gentoo's source-build culture; acceptance in the main tree is
  low, and the realistic entry point is overlay/GURU;
- self-unpacking the AppImage inside the ebuild depends on an executable runtime;
  it was verified with the Gentoo 2.18 / Portage 3.0.83 test environment;
- `RDEPEND` now lists the direct runtime libraries, but `CHOST`/`USE`/`SLOT`
  combinations are not covered;
- `chrome-sandbox` setuid may conflict with Gentoo's `suid` policy/`FEATURES`;
- the maintainer email in `metadata.xml` is a private-overlay placeholder;
  GURU/main-tree submission needs a real contact or a Gentoo proxy maintainer;
- `pkgdev manifest` downloads both arch AppImages once; normal `emerge` downloads only
  the current architecture.

---

## 4. Local check script

**Files.** `scripts/package-distro-formats.sh`.

```bash
# all channels, static checks (default)
scripts/package-distro-formats.sh

# check only a few
scripts/package-distro-formats.sh aur nix

# attempt real builds on hosts where the tools are available; missing tools report SKIP, never a false verified
scripts/package-distro-formats.sh --build
```

The script does the following:

1. `bash -n` on the PKGBUILD/ebuild/itself;
2. AUR: source variables, dual architecture, URLs, non-SKIP checksums; compares the local AppImage
   sha256; if `makepkg` is available, compares `.SRCINFO`; with `--build`, runs `makepkg` in a
   temporary directory;
3. Snap: PyYAML/Ruby YAML parsing + key field checks; with `--build` and `snapcraft` available,
   replaces the source with the local AppImage and then runs `snapcraft pack --destructive-mode`;
4. OBS: XML parsing + spec text checks; with `--build` and `rpmbuild` available, local
   `rpmbuild -bb`;
5. Nix: `nix-instantiate --parse` (if present) + structural checks; `nix build` with `--build`;
6. Gentoo: `bash -n` + structural checks;
7. finally outputs a `channel / lint / build / verified` table; `verified` is set to `BUILD-ONLY`
   only when the channel build actually ran successfully; `YES` requires install + launch
   acceptance. This round AUR reached `YES`, while Snap/OBS reached `BUILT` but were not
   installed/launched.

Actual output on this machine (2026-11-10, without `--build`):

```text
CHANNEL  LINT   BUILD      VERIFIED
aur      PASS   BUILT      YES (pacman -Udd + Xvfb)
snap     PASS   BUILT*     BUILD-ONLY (manual squashfs)
obs      PASS   BUILT*     BUILD-ONLY (local rpmbuild)
nix      PASS   NOT RUN    NO
gentoo   PASS   NOT RUN    NO

Lint: PASS=11 FAIL=0 SKIP=6
```

The historical script skipped `makepkg`, `snapcraft`, `rpmspec`, `rpmlint`,
`nix-instantiate` and `pkgcheck` when those tools were absent. The Gentoo ebuild has
since been validated separately on Gentoo 2.18 with pkgcheck 0.10.49.

Actual result of running `--build aur` in the Arch container (`DSHD_APPDIR=/appdir`, skipping the
non-executable AppImage runtime):

```text
[PASS] AUR package built: /tmp/.../deepseek-harness-bin-0.2.2_rc.1-1-x86_64.pkg.tar.zst
-> aur      lint=PASS build=BUILT verified=BUILD-ONLY
```

Note: the script's `verified=BUILD-ONLY` only means that channel's **package build** succeeded; it
does not mean GUI install/launch acceptance.

---

## 5. Still required before release

1. **Confirm the real GitHub Releases URL/asset names**; this repository has currently proven only
   the local `dist/` files, not that the upstream release has been uploaded.
2. **Install + launch on real target distributions**:
   - Arch x86_64: launch in Xvfb/on real hardware after `pacman -U`;
   - Arch aarch64: build and install;
   - openSUSE Leap/Tumbleweed: `osc build` + `zypper install`, check AppArmor/SELinux;
   - NixOS: `nix build`/`nix run`, verify ELF patchelf and the userns sandbox;
   - Gentoo: keep the overlay ebuild and repeat `pkgcheck` + `emerge` on release bumps;
   - Snap: `snap install --dangerous` + `snap connections` in an LXD/VM (Docker has no snapd).
3. **Signing**: the upstream AppImage/RPM is still unsigned; the checksums for AUR/OBS/Gentoo/Nix
   only guarantee "the file did not change", not publisher identity. Real release GPG keys and a
   signing chain per channel are needed.
4. **Automation**: put per-channel builds into the CI matrix; the AUR `.SRCINFO` update, Snap's
   `snapcraft lint`, OBS's `osc results`, and Nix's `nix flake check` should all become gates.
5. **Permission model**: the capability gap of Snap strict is a product-level problem that YAML
   cannot solve; a decision is needed on whether to apply for classic, or to state explicitly that
   Snap only offers a restricted mode.
6. **Flatpak 25.08** x64/arm64 bundles have both been rebuilt and passed install/launch acceptance
   (see the release documentation).

---

## 6. File inventory

```text
packaging/aur/PKGBUILD
packaging/aur/.SRCINFO
packaging/snap/snapcraft.yaml
packaging/snap/icon.png
packaging/obs/deepseek-harness.spec
packaging/obs/_service
packaging/nix/package.nix
packaging/nix/flake.nix
packaging/gentoo/deepseek-harness-bin-0.2.2_rc1-r3.ebuild
scripts/package-distro-formats.sh
docs/distro-packaging-implementation.md
```

`README.md`, `docs/distro-packages.md`, `docs/release.md`, `patches/`, `scripts/cdp.mjs`,
`evidence/`, and `dist/` were not modified.

## Earlier 2026-11-10 retry notes (superseded)

These were transient failures during the day, not the final channel status:

- **Snap**: the Ubuntu 24.04 repositories no longer provided the `snapcraft` deb and the
  `snapcraft/snapcraft:8` image could not be pulled; the final `.snap` was assembled manually
  from the installed AUR payload with squashfs. It is still not `snap install`-verified.
- **OBS**: early package-source downloads timed out; a later local `rpmbuild` succeeded and
  produced the 273 MB RPM. The OBS service build and signing remain unverified.
- **Nix / Gentoo**: no `nix`/`portage` toolchain was available; both remain statically checked.
- **arm64 Flatpak 25.08**: an early Platform download stalled; after pre-seeding the Flathub
  summary it completed, and the bundle passed install/launch verification (see
  `evidence/flatpak-2508-arm64-verify.txt`).

None of the final statuses above should be read as an OBS/Snap Store release.
