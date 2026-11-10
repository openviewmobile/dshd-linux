# Linux 发行版与包格式支持研究

> 状态：**研究 / 规划文档（2026-11-10）**。本文不重建产物，格式“已实现”与否以
> 仓库现有补丁、脚本和 `evidence/` 为准；未实现的部分明确标为“计划”或“不支持”。
>
> 结论先行：
>
> - **已产出并验证**：AppImage、deb、rpm、Flatpak（单文件 bundle），arm64 与 x64 都有。
> - **尚未实现**：Snap、Arch/AUR、openSUSE OBS 仓库、Alpine、Gentoo、Nix；也没有任何
>   应用商店上架、发布签名或自动更新。
> - **硬约束**：Alpine 是 musl，官方 Electron 预编译产物是 glibc，**不能直接运行**；
>   这不是打包问题，而是运行时 ABI 问题。
> - **当前最紧急的维护项**：Flatpak 使用的 `org.freedesktop.Platform//24.08` 已于
>   **2026-09 EOL**，继续分发会积累安全与兼容风险，需要评估升级到 25.08/26.08。
> - **支持基线建议**：glibc ≥ 2.32，即 Debian 12+、Ubuntu 22.04+、RHEL 9+、
>   openSUSE Leap 15.6+、Arch、Gentoo、NixOS；RHEL 8 / Debian 11 / Ubuntu 20.04
>   不承诺（原因见 [§4.2](#42-glibc-基线与-artifact-实测)）。

---

## 1. 当前仓库的真实状态

现有 Linux 打包链路见 [architecture.md](architecture.md)、[release.md](release.md) 和
[testing.md](testing.md)。构建入口是 [scripts/package-formats.sh](../scripts/package-formats.sh)
与 [Dockerfile](../Dockerfile)；格式配置在
[patches/0002-linux-deb-rpm-flatpak.patch](../patches/0002-linux-deb-rpm-flatpak.patch)。

| 格式 | 架构 | 版本 / 体积 | 已验证内容 | 状态 |
|---|---|---|---|---|
| AppImage | arm64 / x64 | 0.2.2-rc.1；约 349 MB / 354 MB | Xvfb 中启动，窗口与 Host 正常 | ✅ 已产出；未签名、无自动更新 |
| deb | arm64 / x64 | 262 MB / 278 MB | `dpkg-deb -I` 元数据；x64 在 amd64 Docker + Xvfb 安装并启动 | ✅ 已产出；无 APT 仓库 |
| rpm | arm64 / x64 | 216 MB / 229 MB | `rpm -qpi` 元数据；未做 Fedora/RHEL 真机安装 | ✅ 已产出；无 DNF 仓库 |
| Flatpak | arm64 / x64 | 226 MB / 239 MiB | bundle 安装、ref/runtime 检查；x64 在 Docker 中绕过 bwrap 限制后 GUI 冒烟 | ⚠️ 已产出 bundle；**未提交 Flathub**，runtime 已 EOL |
| Snap | — | — | — | ⚪ 未实现（研究） |
| Arch `pkg.tar.zst` / AUR | — | — | — | ⚪ 未实现（研究） |
| openSUSE OBS 仓库 | — | — | — | ⚪ 未实现（研究） |
| Alpine `apk` | — | — | — | ⛔ 不兼容（musl） |
| Gentoo ebuild | — | — | — | ⚪ 未实现（研究） |
| Nix / NixOS | — | — | — | ⚪ 未实现（研究） |

依据：

- [evidence/formats-verification.txt](../evidence/formats-verification.txt)（arm64 deb/rpm/Flatpak 元数据与 SHA-256）；
- [evidence/x64-flatpak.txt](../evidence/x64-flatpak.txt)（x64 Flatpak 239 MiB、`com.deepseek.harness/x86_64/master`、
  `org.freedesktop.Platform/x86_64/24.08`）；
- [evidence/flatpak-x64-smoke.txt](../evidence/flatpak-x64-smoke.txt)（Docker 内 Flatpak GUI 冒烟，真实主机不需要 bwrap workaround）；
- [evidence/signing.txt](../evidence/signing.txt)（仅测试 GPG 签名；**不是发布签名**）。

应用本身：`@deepseek-ai/dsh-desktop@0.2.2-rc.1`，Electron **44.7.0**（Chromium 152 / Node 24.21），
内置 Node、pnpm、Python、ripgrep 与 dsh 生产依赖。Electron 44 的平台支持口径见
[Electron v44.7.0 README](https://github.com/electron/electron/blob/v44.7.0/README.md)：
官方 x64/arm64 Linux 二进制**在 Ubuntu 上构建**，只承诺 Chromium 与发行版双方都仍支持的版本。

---

## 2. 总览矩阵

> “相对量级”是规划用的数量级判断，不是精确装机统计。Linux 桌面没有权威的发行版级
> 份额数据；这里只用于排序，不作为发布承诺。
>
> 状态图例：✅ 已产出并验证；⚠️ 已产出但有明显缺口；⚪ 计划/研究；⛔ 明确不支持。

| 发行版 / 渠道 | 目标用户与相对量级 | 原生格式与工具 | 构建 / 签名 | 沙箱 / 更新 | 依赖 / 运行时 | 预估工作量 | 仓库现状 | 主要缺口 / 风险 |
|---|---|---|---|---|---|---|---|---|
| **Debian / Ubuntu 及衍生版**（Ubuntu、Mint、Pop!_OS、Kali、Deepin 等） | 桌面 Linux 最大一档；Ubuntu 主导，Debian 次之 | `deb` + APT；`dpkg-deb`、`reprepro`/`aptly` | electron-builder + fpm；`debsigs`/仓库 `Release.gpg`；`lintian` | 无应用沙箱；APT 仓库或手动下载；无内建更新器 | 依赖系统 GTK3/NSS/X11 等；Electron/Node/Python 全部内置；glibc | 维护 1–2 人日/版；建 APT 仓库 +2–3 人日 | ✅ deb 已产出（arm64/x64） | 无 APT 仓库；Ubuntu 24.04 t64 已提供旧名，Debian 13/arm64 待实测；未签名 |
| **Fedora / RHEL / CentOS Stream / Rocky / Alma** | 第二大档；Fedora 桌面 + RHEL 工作站/企业 | `rpm` + DNF/YUM；`rpmbuild`、`createrepo_c` | electron-builder + fpm；`rpmsign`/`rpm --addsign`；`rpmlint` | 无应用沙箱；DNF 仓库或手动；无内建更新器 | `gtk3`、`nss`、`libnotify`、`libXScrnSaver`、`at-spi2-core`、`xdg-utils`、`libXtst`、`libuuid`；glibc | 维护 1–2 人日/版；多版本验证 +2 人日 | ✅ rpm 已产出（arm64/x64） | RHEL 8（glibc 2.28）低于基线；RHEL 7/CentOS 7 已 EOL（YUM 不支持）；未做真机安装；未签名 |
| **openSUSE / SLES** | 小众但稳定；欧洲企业与 SUSE 生态 | `rpm` + Zypper；OBS 可同时产 rpm/deb/AppImage | OBS（`osc`、`_service`、spec）；OBS 项目密钥签名；`rpmlint` | 无应用沙箱；OBS 仓库 + `zypper up` | 同 RPM 家族，包名略有差异；glibc | OBS 建项目 3–5 人日；每版 1 人日 | ⚪ 未实现 | 需要单独 spec/`_service`；SELinux/AppArmor 未验证；OBS 构建无网络 |
| **Arch / Manjaro / EndeavourOS** | 开发者/技术用户密度高；总量中等 | `pkg.tar.zst` + pacman；AUR | `makepkg`、`namcap`；`makepkg --sign` / pacman-key | 无应用沙箱；`pacman -Syu`；AUR helper | 系统 GTK3/NSS 等；**必须自带 Electron**（见 §4.4） | AUR `-bin` 2–3 人日；原生 5–8 人日 | ⚪ 未实现 | 系统 `electron` 不能用于 `ELECTRON_RUN_AS_NODE`；AUR 非官方仓库；滚动升级 ABI 风险 |
| **Alpine Linux** | 服务器/容器为主，桌面极少 | `apk`；`abuild` | `abuild -r`、`abuild-sign`、`apk index`；APKBUILD | 无应用沙箱；`apk upgrade` | **musl**；官方 Electron 为 glibc；Alpine `testing/electron` 是 musl 源码重建且版本滞后 | 15–30 人日起，且大概率不可行 | ⛔ 不支持 | Electron 官方二进制不可运行；gcompat 不可靠；需从源码重建 Electron + 原生模块 + Python |
| **Gentoo** | 极小众；源码/技术用户 | `ebuild` + Portage | `ebuild`、`pkgcheck`、`repoman`；GPG 签名 Manifest | 无应用沙箱；`emerge -u` | 系统 glibc 库；可解包 AppImage 或自带 Electron | 5–8 人日 | ⚪ 未实现 | 主树无通用 Electron ebuild（截至调研）；QA/许可证审查；滚动 ABI |
| **NixOS / Nix** | 小众但增长快；开发者/可复现构建用户 | Nix derivation / flake | `nix-build`、`nix flake check`、`nixpkgs-review`；二进制缓存签名 | 无运行时沙箱；`nix profile upgrade` / `nixos-rebuild` | nixpkgs 库 + `autoPatchelfHook`；官方 Electron 或 nixpkgs Electron | 5–10 人日 | ⚪ 未实现 | 官方 Electron 与 nixpkgs 版本可能不一致；setuid sandbox 在只读 store 不可用；需 FHS/patchelf 处理 |
| **Snap**（snapd / Snap Store） | Ubuntu 预装，触达广；跨发行版可用 | `snap`；snapcraft | `snapcraft pack`、`snapcraft lint`；Store 审核/签名 | AppArmor + seccomp；snapd 自动 refresh；通道 | `base: core24` 提供 Ubuntu 24.04 用户空间；应用自带 Electron；`stage-packages` 补库 | PoC 5–8 人日；商店审核 2–6 周 | ⚪ 未实现 | dsh 需要本地 shell/文件/网络，strict 权限可能不够；classic confinement 需 Store 人工批准 |
| **Flatpak**（Flathub / 自建 OSTree） | 跨发行版，Flathub 增长快 | `.flatpak` bundle / OSTree repo | `flatpak-builder`、`flatpak build-sign`、`flatpak build-update-repo`；`flatpak-builder-lint` | bubblewrap 沙箱；`flatpak update`；Portals | `org.freedesktop.Platform//24.08` + `org.electronjs.Electron2.BaseApp//24.08` | 维护 2–4 人日/版；升级 runtime 3–5 人日；Flathub 源码化 15–30 人日 | ⚠️ bundle 已产出（arm64/x64） | **24.08 已 EOL**；未上 Flathub；Flathub 要求源码构建、禁预编译二进制；开发工具类审核严格 |
| **AppImage** | 下载型分发；开发者/不想装包的用户 | `.AppImage`（type 2） | electron-builder + `appimagetool`；`--sign`；zsync/更新信息 | 无沙箱；手动下载；可选 AppImageUpdate | 自带 Electron/Node/Python；依赖系统 GTK3/NSS 等；glibc | 维护 0.5–1 人日/版 | ✅ 已产出（arm64/x64） | 无自动更新；未签名；Ubuntu 24.04 userns 限制可能影响 Chromium sandbox；体积大 |

补充说明：

- **CentOS Linux 8** 已 EOL，**CentOS Stream 9/10** 才是当前路线；**RHEL 7/CentOS 7**
  的 YUM 生态已 EOL，不在支持范围。
- **Deepin / UOS** 使用 deb，但桌面环境与系统库版本差异大，按 Debian 衍生版对待，
  需单独验证。
- **portable tar.gz** 未列入正式格式：它不能解决依赖、桌面集成、更新与签名，价值低于
  AppImage；如有需要，可作为调试/CI 产物，不作为用户分发格式。

---

## 3. 分发行版 / 格式详解

### 3.1 Debian / Ubuntu 及衍生版（deb / APT）

**目标用户。** Ubuntu 是桌面 Linux 的事实默认选择，Debian 稳定版覆盖服务器与保守桌面；
Mint、Pop!_OS、Kali、Deepin 等直接复用 deb。该家族应作为第一优先级。

**格式与工具。** `deb` 由 electron-builder 的 fpm 后端生成，本质是 `ar` 归档 +
`control.tar.xz` + `data.tar.xz`。规范见
[Debian Policy](https://www.debian.org/doc/debian-policy/) 与
[Ubuntu Packaging Guide](https://packaging.ubuntu.com/html/)。质量检查用
[Lintian](https://lintian.debian.org/)。仓库发布通常用 `reprepro` 或 `aptly` 生成
`Packages`/`Release` 并由 `Release.gpg` 签名；单包签名可用 `debsigs`/`dpkg-sig`
（后者已不推荐）。

当前 artifact 的 `Depends`（实测）：

```text
libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6, xdg-utils,
libatspi2.0-0, libuuid1, libsecret-1-0
Recommends: libappindicator3-1
```

**风险。**

1. **t64 包重命名**：Ubuntu 24.04 / Debian 13 起，`libgtk-3-0`、`libatspi2.0-0` 等改为
   `libgtk-3-0t64`、`libatspi2.0-0t64`。当前 deb 元数据仍写旧名。已实测 Ubuntu 24.04
   的 t64 包提供旧名（`libgtk-3-0t64` 的 `Provides:` 含 `libgtk-3-0`；
   `libatspi2.0-0t64` 提供 `libatspi2.0-0`；`libatk1.0-0t64`/`libcups2t64` 同理），
   因此理论上可解析；但 Debian 13、arm64 以及实际安装仍需在目标镜像验证，
   不能只看元数据。
2. **无 APT 仓库**：现在只有单文件 deb，用户需手动下载；没有 `apt upgrade` 路径。
3. **无发布签名**：`SHA256SUMS` 只有测试 GPG 签名，见 [evidence/signing.txt](../evidence/signing.txt)。
4. **Lintian 预期告警**：内嵌 Electron/Node、无 manpage、`Section: default`、
   maintainer script 等；需要设定可接受的告警基线。

**更新模型。** deb 自身不带更新器。可选：自建 APT 仓库（推荐，配合 `apt` 的原生更新）；
或在应用内实现自有 updater（工作量大、权限复杂）。不建议依赖 electron-updater 的
Linux deb 路径作为唯一方案。

**验证。** 见 [§5](#5-验证与-ci-矩阵)。

**工作量。** 现有格式维护 1–2 人日/版；补 APT 仓库、签名与多版本验证 3–5 人日。

---

### 3.2 Fedora / RHEL / CentOS Stream / Rocky / Alma（rpm / DNF/YUM）

**目标用户。** Fedora 是新技术采纳最快的桌面/开发发行版；RHEL、Rocky、Alma 覆盖企业
工作站与受管桌面；CentOS Stream 是 RHEL 上游。RHEL 8 及更早版本因 glibc 2.28 低于
本项目基线，**不承诺**；RHEL 9/10 与对应克隆版是目标。

**格式与工具。** `rpm` 由 fpm 生成。规范见
[Fedora Packaging Guidelines](https://docs.fedoraproject.org/en-US/packaging-guidelines/) 与
[RPM Packaging Guide](https://rpm-packaging-guide.github.io/)。检查用
[rpmlint](https://github.com/rpm-software-management/rpmlint)；签名用 `rpmsign --addsign`
或 `rpm --addsign`；仓库用 `createrepo_c` + `dnf` 的 `repo_gpgcheck`。

当前 artifact 的 `Requires`（实测，自动生成的 soname/包名依赖）：

```text
gtk3, nss, libnotify, libXScrnSaver, at-spi2-core,
xdg-utils, (libXtst or libXtst6), (libuuid or libuuid1), /bin/sh
```

注意：fpm 生成的 rpm **没有** `Recommends:` 弱依赖，托盘图标所需的
`libappindicator-gtk3` 不会自动安装；Debian 侧有 `Recommends: libappindicator3-1`，
rpm 侧需要在 spec 中显式补 `Recommends`/`Suggests`，或在文档中说明。

**风险。**

1. **RHEL 8 / CentOS 8**：glibc 2.28，低于 §4.2 的 2.32 基线；不应发布。
2. **SELinux**：`/opt/DeepSeek Harness` 下的 setuid `chrome-sandbox` 可能触发
   `selinux` 拒绝；需要在 enforcing 的 Fedora/RHEL 上验证，必要时提供策略或改用
   user namespace sandbox。
3. **无 DNF 仓库**：当前只有单文件 rpm；企业环境通常需要内网仓库。
4. **未做真机安装**：目前只有 `rpm -qpi` 元数据检查，缺少 Fedora/Rocky 的安装+启动证据。

**更新模型。** 自建 DNF 仓库（`createrepo_c` + GPG 签名）最符合原生体验；否则手动
下载。应用内更新器同样未接入。

**工作量。** 维护 1–2 人日/版；RHEL 9/10、Rocky、Fedora 多版本验证与 spec 调整
3–5 人日；建仓库 +2 人日。

---

### 3.3 openSUSE / SLES（rpm / Zypper / OBS）

**目标用户。** openSUSE Leap/Tumbleweed 与 SLES 的企业/欧洲用户；总量不大，但
openSUSE 的 OBS 能把 rpm、deb、AppImage 一起构建和发布，是“一次投入、多格式产出”的
高杠杆渠道。

**格式与工具。** 运行时仍是 rpm + Zypper，但**不建议手工维护第二套 rpm 构建**；应使用
[Open Build Service（OBS）](https://openbuildservice.org/help/manuals/obs-user-guide/)：

- `osc` 客户端 + 项目（`home:<user>` 起步，成熟后提交到 devel 项目）；
- `_service` 文件用 `tar_scm`/`download_files` 拉取源码，保证 OBS 构建可复现；
- `*.spec` 写 `BuildRequires`/`Requires`，OBS 在干净 chroot 中构建（构建期无网络）；
- OBS 项目密钥自动签名 rpm/deb 仓库；发布 `repodata`；
- 可同时产 AppImage（OBS 的 AppImage 构建能力）与 deb，但 deb 质量不如 Debian 原生链路。

openSUSE 包名与 Fedora 基本一致，但 `libappindicator` 等可选依赖的可用性需在
Leap/SLES 的仓库中确认；SLES 默认仓库较窄，可能需要 Package Hub 或自建依赖。

**风险。**

1. OBS 构建无网络，Node/pnpm/Python 资产必须预先 vendor 或走 `_service`；
2. OBS 的 arm64 worker 资源有限，arm64 构建排队可能较慢；
3. SLES 的订阅/仓库差异，不能假设 Leap 的依赖在 SLES 上都有；
4. 需要维护 spec 与 `_service`，与现有 fpm 链路是两套逻辑。

**更新模型。** OBS 仓库 + `zypper up`，体验最好；也可只发布单 rpm。

**工作量。** OBS 项目搭建与首版 3–5 人日；每版 1 人日；若同时维护 spec 与 fpm，
长期维护成本增加约 30%。

---

### 3.4 Arch / Manjaro / EndeavourOS（pacman `pkg.tar.zst` / AUR）

**目标用户。** Arch 及衍生版用户总量中等，但开发者、技术意见领袖和“愿意写 issue/PR”
的用户密度最高；AUR 是低成本触达这批人的渠道。

**格式与工具。** `PKGBUILD` + `makepkg` 生成 `pkg.tar.zst`，pacman 安装。规范见
[Arch PKGBUILD](https://wiki.archlinux.org/title/PKGBUILD) 与
[AUR](https://wiki.archlinux.org/title/Arch_User_Repository)；质量检查用
[namcap](https://wiki.archlinux.org/title/Namcap)；签名用 `makepkg --sign` + pacman-key。
AUR 只托管 `PKGBUILD` 与构建脚本，不托管二进制；`-bin` 包可以下载官方 AppImage/deb
并重打包，但必须声明来源与许可证。

**关键约束：不能用系统 Electron。** Arch 确实提供 `electron` 元包和版本化
`electron44`（调研时 `extra/electron 1:44-1`，依赖 `electron44`），但
[ArchWiki Electron package guidelines](https://wiki.archlinux.org/title/Electron_package_guidelines)
明确写道：**需要 `ELECTRON_RUN_AS_NODE=1` 的应用（如 VS Code）不能使用
`/usr/bin/electron*`**。本项目桌面壳正是用 `ELECTRON_RUN_AS_NODE` 启动内置 Host，
因此必须把 Electron 运行时随包自带，安装到 `/opt/deepseek-harness`，而不是依赖
系统 Electron。

**两条路线。**

1. **AUR `deepseek-harness-bin`（推荐先做）**：`source` 指向官方 AppImage 或 deb，
   `package()` 中解包，安装到 `/opt/deepseek-harness`，提供 `/usr/bin/deepseek-harness`
   wrapper、`.desktop`、图标；`depends` 写 GTK3/NSS 等系统库。优点：复用已验证产物，
   2–3 人日；缺点：不是从源码构建，AUR 社区对 `-bin` 的接受度取决于维护质量。
2. **原生 `deepseek-harness`**：从源码构建 Electron 应用，`electronDist` 指向自带的
   Electron 44，避免下载；需要处理 pnpm、Python、原生模块、`app.asar` 与
   `chrome-sandbox` 权限。5–8 人日，且每次 Electron 升级都要跟进。

**从 AppImage 重打包的注意点。**

- `--appimage-extract` 后保留 `usr/` 结构；不要 `strip` Electron/Node 二进制；
- `chrome-sandbox` 需要 root:root + 4755，否则 Chromium sandbox 启动失败；PKGBUILD
  在 fakeroot 下可用 `chmod 4755`，但要在 `.INSTALL`/文档中说明安全含义；
- AppImage 的 `.desktop` 中 `Exec` 指向 AppRun，重打包后要改成 `/usr/bin/deepseek-harness`；
- `namcap` 会对“未声明依赖”“文件权限”“多余文件”告警，需要逐项处理。

**更新模型。** pacman/AUR helper 更新；没有应用内更新。滚动发行版的 Electron/GTK ABI
变化可能导致旧包失效，需要定期重建。

**工作量。** AUR `-bin` 2–3 人日；原生 5–8 人日；进入 `extra` 仓库需要 TU 提名与
源码构建，短期不现实。

---

### 3.5 Alpine Linux（apk）——明确不兼容

**结论：v1 不支持，且不是“再写一个 APKBUILD”能解决的问题。**

**原因链。**

1. 官方 Electron 预编译二进制是 **glibc** 构建；Electron README 明确“prebuilt binaries
   are built on Ubuntu”。Alpine 使用 **musl libc**，ELF 解释器与符号版本都不匹配，
   直接执行会报 `not found` 或加载器错误。
2. 本项目产物不仅含 Electron，还含内置 Node 24、Python、`node-pty`、`sharp`、`koffi`、
   `sherpa-onnx` 等原生模块；它们中的大多数是 glibc 预编译（见 §4.2 的符号扫描）。
   `gcompat` 只能覆盖少量符号，不能可靠支撑 Chromium/Electron 的完整运行时。
3. Alpine 确实有一个 `electron` 包，但它是 **Alpine 自己从源码用 musl 重建**的：
   调研时 `testing/x86_64/electron` 为 **42.11.18-r0**，依赖 `so:libc.musl-x86_64.so.1`，
   见 [Alpine package: electron](https://pkgs.alpinelinux.org/package/edge/testing/x86_64/electron)。
   它与本项目的 Electron 44 不同版本，且位于 `testing`，不能直接复用。
4. 即使强行用 Alpine 的 Electron 42 启动，也会遇到 `ELECTRON_RUN_AS_NODE`、原生模块
   ABI、Node 24 内置运行时、Python 扩展等一系列不匹配。

**如果一定要支持，需要做什么。**

- 在 Alpine 上从源码构建 Electron 44（Chromium 构建，数十 GB、数小时，且需要大量
  musl patch）；
- 用 musl 重新编译所有原生模块与 Python 运行时；
- 维护独立的 `electron` 版本线与安全更新；
- 这会变成一条独立产品线，而不是“增加一个包格式”。

**建议。** 在支持矩阵中明确写“Alpine 不支持”，并给出原因与替代方案（容器/远端使用
dsh CLI，或等待上游提供 musl 构建）。不要发布 `apk` 包，避免用户安装后无法启动。

**工作量。** 15–30 人日起，成功率低；不建议投入。

---

### 3.6 Gentoo（ebuild）

**目标用户。** 极小而高粘性的源码用户；对“能自己编译/控制依赖”的人群有象征意义，
但商业优先级低。

**现状。** 截至调研，Gentoo 主树没有通用的 `dev-util/electron` ebuild（GitHub 主树
目录与 packages.gentoo.org 搜索均未发现）；Electron 应用通常由应用自身 ebuild
解包上游二进制/AppImage，或使用 bundled Electron。规范见
[Gentoo Devmanual: ebuild writing](https://devmanual.gentoo.org/ebuild-writing/)；
检查用 [pkgcheck](https://wiki.gentoo.org/wiki/Pkgcheck)。

**可行路线。**

1. **`deepseek-harness-bin` ebuild**：`SRC_URI` 指向官方 AppImage 或 deb，
   `src_unpack()` 解包，`src_install()` 安装到 `/opt/deepseek-harness`，安装 wrapper、
   `.desktop`、图标；`RDEPEND` 写 `x11-libs/gtk+:3`、`dev-libs/nss`、`x11-libs/libXScrnSaver` 等。
2. **源码 ebuild**：从源码构建，依赖系统 Node/pnpm/Python，工作量大且与上游构建链耦合。

**风险。**

- Gentoo 的 `USE` 旗标、`SLOT`、`CHOST`/`ABI` 组合多，测试矩阵爆炸；
- 预编译二进制与 Gentoo 的“从源码构建”文化冲突，可能只能进 overlay（如 GURU），
  进主树需要维护者与许可证/QA 审查；
- 滚动升级导致 Electron/GTK ABI 变化，需要持续重建。

**更新模型。** `emerge -u`；无应用内更新。

**工作量。** 5–8 人日（overlay 首版）；主树审核不确定。

---

### 3.7 NixOS / Nix（nixpkgs）

**目标用户。** 小众但增长快，开发者、可复现构建与 CI 用户集中；一次 derivation 可以
同时服务 NixOS 与非 NixOS 的 Nix 用户。

**两种 derivation 路线。**

1. **快速路线：包装 AppImage**。使用 nixpkgs 的
   [`appimageTools.wrapType2`](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-appimageTools)
   解包并 wrap，配合 `autoPatchelfHook` 修正 ELF 解释器与 RPATH。优点是几天内可用；
   缺点是闭包大、启动路径多一层、更新要改 hash，且 Nix 社区通常不接受“只包装二进制”
   作为 nixpkgs 正式包。
2. **原生路线：`stdenv.mkDerivation` + 官方 Electron 解包**。把 electron-builder 的
   `linux-unpacked` 作为 `src`，用 `autoPatchelfHook` 处理所有 ELF，`makeWrapper` 设置
   `ELECTRON_RUN_AS_NODE`、`PATH`、`LD_LIBRARY_PATH`；`buildInputs` 写 GTK3/NSS 等。
   这是更可维护的长期方案，但需要处理：
   - Electron 官方二进制的 setuid `chrome-sandbox` 在 Nix store 中不可用（store 只读、
     无 setuid）；通常改用 user namespace sandbox，或在 wrapper 中加
     `--disable-setuid-sandbox`（安全性需评估）；
   - 原生模块的 RPATH、Python 解释器路径、`pnpm` 路径都要 patch；
   - 若要从源码构建，需要 `fetchNpmDeps`/`buildNpmPackage` 与 pnpm 离线缓存，
     工作量显著增加。

**示意（仅说明结构，未实现、未测试）：**

```nix
{ lib, fetchurl, appimageTools
, gtk3, nss, libnotify, libXScrnSaver, at-spi2-core, xdg-utils, libxtst, util-linux
}:

let
  pname = "deepseek-harness";
  version = "0.2.2-rc.1";
  src = fetchurl {
    url = "https://example.invalid/${pname}-${version}-x86_64.AppImage";
    hash = lib.fakeHash; # 发布时替换为真实 SRI hash
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

真正的原生 derivation 还应把 `appimageTools.wrapType2` 换成
`stdenv.mkDerivation` + `autoPatchelfHook` + `makeWrapper`；不要直接复制上面的
`extraPkgs` 列表当成完整依赖。

**验证。** `nix-build`、`nix flake check`、`nix run`、`nixpkgs-review`；NixOS 上还需
在真实 Wayland/X11 会话验证。

**风险。**

- nixpkgs 的 Electron 版本与本项目锁定的 44.7.0 可能不一致；用系统 Electron 会引入
  `ELECTRON_RUN_AS_NODE`/ABI 风险，建议自带；
- 只读 store 与 Chromium sandbox 的冲突；
- 闭包体积大（Electron + Node + Python 约 1 GB 级）；
- 进 nixpkgs 主树需要 maintainer、许可证与构建可复现性审查，周期长。

**工作量。** `appimageTools` 包装 2–3 人日；原生 derivation 5–10 人日；进 nixpkgs
另计审核时间。

---

### 3.8 Snap（snapd / Snap Store）

**目标用户。** Ubuntu 预装 snapd，触达所有 Ubuntu 用户；其他发行版也可安装 snapd。
Snap Store 是 Canonical 运营的集中式商店，审核与自动更新由 Store 负责。

**格式与工具。** `snapcraft.yaml` + `snapcraft pack`；检查用 `snapcraft lint`；发布用
`snapcraft upload`/`release`，Store 侧签名。Electron 有两条路：

1. **electron-builder 的 `snap` target**：Snapcraft 文档明确 Electron 支持 snap，
   electron-builder 22.7+ 可直接 `electron-builder --linux snap`
   （见 [Craft an Electron app](https://ubuntu.com/docs/snapcraft/9.2/how-to/integrations/craft-an-electron-app/)）。
   本项目当前 target 列表只有 AppImage/deb/rpm/flatpak，增加 `snap` 是配置改动。
2. **自写 `snapcraft.yaml`**：`plugin: dump` 解包现有 deb/AppImage，`base: core24`，
   `confinement: strict`（或 `classic`），`apps.<name>.command` 指向 wrapper，
   `extensions: [gnome]` 提供 GTK 主题/库，`stage-packages` 补 `libnss3`、`libxss1` 等。

**关键约束：沙箱与产品能力冲突。** dsh 是本地 Agent，需要：

- 读写用户工作区（可能在 `$HOME` 之外）；
- 执行 shell、`git`、`pnpm`、Python；
- 访问网络、本地端口、进程信息；
- 安装/运行插件（写 `~/.dsh`、项目目录）。

Strict confinement 下，`home` 接口只覆盖非隐藏文件，`personal-files` 需要声明具体路径
并可能受 Store 审核；`process-control`、`system-observe` 等接口会增加权限面。若需要
完整本地能力，通常只能申请 **classic confinement**，而 classic 需要 Store 人工批准，
且不能保证通过。对“开发工具”类应用，这是 Snap 路线的最大不确定性。

**运行时。** `base: core24` 对应 Ubuntu 24.04 用户空间（glibc 2.39），满足 §4.2 基线；
Electron/Node/Python 仍随应用自带。`core24` 的支持周期与 Ubuntu 24.04 对齐，需在
Ubuntu 26.04 发布后规划 `core26`。参考
[Snapcraft Bases](https://ubuntu.com/docs/snapcraft/9.2/reference/bases/)。

**更新模型。** snapd 自动 refresh，按 channel（stable/candidate/edge）发布；这是 Snap
相对 deb/rpm 的最大优势，但也意味着必须保证自动升级不破坏本地数据/插件。

**验证。** `snapcraft pack`、`snapcraft lint`；在 LXD/VM 中 `snap install --dangerous`
（Docker 内没有 systemd/snapd，不能作为有效验证）；检查 `snap connections`、实际文件/
网络访问、自动 refresh。

**工作量。** strict PoC 5–8 人日；classic 申请与 Store 审核 2–6 周，且结果不确定。

---

### 3.9 Flatpak（Flathub / 自建 OSTree）

**目标用户。** 跨发行版、沙箱化、图形桌面用户；Flathub 是事实上的应用商店。对
“不想污染系统、希望自动更新”的用户吸引力强。

**现状。** 已产出单文件 bundle：

- app id：`com.deepseek.harness`；
- runtime：`org.freedesktop.Platform/x86_64/24.08`；
- SDK：`org.freedesktop.Sdk/x86_64/24.08`；
- BaseApp：`org.electronjs.Electron2.BaseApp/x86_64/24.08`；
- 安装方式：`flatpak install --user ./deepseek-harness-*.flatpak`；
- 未提交 Flathub，也没有自建 OSTree 仓库。

**紧急问题：24.08 已 EOL。** Freedesktop SDK 的发布表明确写：
`24.08` 发布于 2024/08，支持到 **2026/09，状态 EOL**；当前受支持的是 `25.08`
（到 2027/09）与 `26.08`（到 2028/09）。见
[Freedesktop SDK Release Timeline](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Releases)。
Flathub 的收录政策也明确不接受 EOL runtime/baseapp。因此：

- 继续用 24.08 出 bundle，只能作为“内部/临时”产物，不应作为长期发布；
- 需要把 `flatpak.runtimeVersion`/`baseVersion` 升级到 25.08 或 26.08；
- 升级前必须确认 `org.electronjs.Electron2.BaseApp` 是否有对应分支，以及 Electron 44
  在该 BaseApp 中的兼容性；这一步是**待验证**，本文不假设已可用。

**Flathub 的现实门槛。** 即使升级 runtime，Flathub 仍不是“把 bundle 传上去”：

- **必须从源码构建**，manifest 中不能有预编译二进制；Electron BaseApp 是允许的，
  但应用自身的 dsh/Node/Python 产物不能直接塞进去。见
  [Flathub Requirements](https://docs.flathub.org/docs/for-app-authors/requirements)。
- **构建期无网络**，pnpm/npm/Python 依赖必须用 `flatpak-node-generator` 等工具
  预先展开为 sources；本项目的运行时体积大、依赖多，改造成本高。
- **开发工具/IDE 类**审核严格，通常只接受上游官方提交；本项目是分叉/衍生发行版，
  需要先解决品牌、上游关系与维护承诺。
- **权限最小化**：`--filesystem=home`、`--share=network` 等静态权限会被审查；
  而 dsh 的本地 Agent 能力又确实需要较宽的文件访问。二者存在结构性矛盾。

**建议。** 短期把 Flatpak 定位为“自建 bundle / 自建 OSTree 仓库”，不承诺 Flathub；
中期如果要上 Flathub，单独立项做“源码化 manifest + 权限模型 + AppStream 元数据”，
不要和 runtime 升级混在一起。

**签名与仓库。** `flatpak build-sign` 签 commit，`flatpak build-update-repo --gpg-sign`
签仓库；客户端用 `flatpak remote-add --gpg-import`。单文件 bundle 本身不是更新仓库，
需要额外提供 `.flatpakrepo` 或 OSTree 仓库才能自动更新。

**验证。** `flatpak-builder --repo=...`、`flatpak build-import-bundle`、
`flatpak-builder-lint`、`appstreamcli validate`；GUI 必须在真实主机验证（Docker 内
bwrap seccomp 受限，证据见 [evidence/flatpak-gui.txt](../evidence/flatpak-gui.txt)）。

**工作量。** 每版维护 2–4 人日；runtime 升级 3–5 人日；Flathub 源码化 15–30 人日，
且审核结果不确定。

---

### 3.10 AppImage（跨发行版）

**目标用户。** 不想安装包管理器条目、希望“下载即用”的用户；开发者、CI、临时试用场景。
AppImage 不需要 root，不写系统目录，是最容易分发的格式。

**现状。** electron-builder 已产出 type 2 AppImage，arm64/x64 均在 Xvfb 中启动验证。
文件约 349–354 MB，内含 Electron/Node/Python，启动时挂载 squashfs。

**工具与规范。** 见 [AppImage Packaging Guide](https://docs.appimage.org/packaging-guide/index.html)。
签名用 `appimagetool --sign`（嵌入式 GPG 签名），更新信息用
`--updateinformation` + zsync，客户端可用 AppImageUpdate；参考
[Signing AppImages](https://docs.appimage.org/packaging-guide/optional/signatures.html) 与
[Making AppImages updateable](https://docs.appimage.org/packaging-guide/optional/updates.html)。

**风险。**

1. **无自动更新**：当前没有 zsync/更新信息；用户需手动下载新版本。
2. **未签名**：`appimagetool --sign` 未接入；GPG 公钥分发也是问题。
3. **Chromium sandbox 与 userns**：Ubuntu 23.10+ 默认限制非特权 user namespace；
   AppImage 内的 `chrome-sandbox` 无法像 deb 那样设置 setuid，可能导致启动失败或被迫
   `--no-sandbox`。需要在 Ubuntu 24.04 真机验证，并优先使用 userns/沙箱兼容方案，
   不能把 `--no-sandbox` 作为发行默认。
4. **FUSE**：无 FUSE 的环境需 `--appimage-extract-and-run`；Docker 测试即如此。
5. **体积**：350 MB 下载对国内网络不友好，需要镜像/断点续传。

**更新模型。** 手动下载 + 可选 zsync/AppImageUpdate；也可在应用内检查版本并提示下载，
但不要在没有签名校验的情况下自动替换二进制。

**工作量。** 每版 0.5–1 人日；接入签名与 zsync 1–2 人日。

---

## 4. 关键技术约束

### 4.1 Electron / Chromium 运行时依赖（按家族）

Electron 的 Linux 运行时依赖并不是“只有 glibc”；图形栈、NSS、AT-SPI、托盘、输入法都
需要系统库。当前 deb/rpm 的依赖是 electron-builder/fpm 自动生成的，基本可用，但不同
家族的包名不同：

| 能力 | Debian/Ubuntu 包名 | Fedora/RHEL 包名 | Arch 包名（参考） |
|---|---|---|---|
| GTK3 | `libgtk-3-0`（24.04+ 为 `libgtk-3-0t64`） | `gtk3` | `gtk3` |
| NSS/NSPR | `libnss3` | `nss` | `nss` |
| 通知 | `libnotify4` | `libnotify` | `libnotify` |
| 屏幕保护/空闲抑制 | `libxss1` | `libXScrnSaver` | `libxss` |
| AT-SPI 无障碍 | `libatspi2.0-0`（t64 变体） | `at-spi2-core` | `at-spi2-core` |
| XTest | `libxtst6` | `libXtst` | `libxtst` |
| UUID | `libuuid1` | `libuuid` | `util-linux-libs` |
| 打开链接/文件 | `xdg-utils` | `xdg-utils` | `xdg-utils` |
| 托盘（可选） | `libappindicator3-1` | `libappindicator-gtk3` | `libappindicator-gtk3` |
| 密钥环（可选） | `libsecret-1-0` | `libsecret` | `libsecret` |

注意：

- deb 的 `Depends` 含 `libsecret-1-0`，rpm 的自动依赖**没有** `libsecret`；如果应用在
  Fedora 上使用系统密钥环，需要在 spec 中补 `Requires: libsecret`。
- `libappindicator` 在 Debian 是 `Recommends`，在 rpm 中没有弱依赖；托盘功能在部分
  Fedora/GNOME 环境可能不可用。
- Wayland 下还需要 `libxkbcommon`、`libwayland-client` 等；Electron 44 的 Wayland 支持
  仍应视为“实验性”，Flatpak 文档也建议默认 X11/XWayland。

### 4.2 glibc 基线与 artifact 实测

Electron 官方 Linux 二进制在 Ubuntu 上构建，**依赖 glibc，不支持 musl**；见
[Electron v44.7.0 README](https://github.com/electron/electron/blob/v44.7.0/README.md)。
本项目当前产物在 `node:24-bookworm`（Debian 12，glibc 2.36）中构建，但“构建机 glibc”
不等于“最低运行 glibc”。对 x64 deb 中的 ELF 做符号版本扫描，得到：

| 组件 | 最高 `GLIBC_*` 符号版本 | 含义 |
|---|---|---|
| Electron 主二进制 | `GLIBC_2.25` | Electron 本身可在较老 glibc 上加载 |
| 内置 Node 24 | `GLIBC_2.28` | Node 运行时下限 |
| `node-pty` | `GLIBC_2.28` | 终端/PTY 功能下限 |
| `sharp` | `GLIBC_2.17` | 图像处理下限 |
| `koffi` | `GLIBC_2.17` | FFI 下限 |
| `sherpa-onnx` | `GLIBC_2.32` | 语音/ONNX 功能下限 |

因此**整个 bundle 的实际下限取最大值 2.32**（前提是 `sherpa-onnx` 会被加载；即使它
懒加载，也不应把“可能崩溃”留给用户）。该扫描基于 ELF 的 `GLIBC_*` 符号字符串，是
启发式下限，不是完整 ABI 分析；发布前仍应在目标 glibc 版本上实际启动。据此：

| 发行版 | glibc | 建议 |
|---|---|---|
| Debian 12 bookworm | 2.36 | ✅ 支持 |
| Debian 13 trixie | 2.41 | ✅ 支持（需验证 t64 依赖） |
| Ubuntu 22.04 | 2.35 | ✅ 支持 |
| Ubuntu 24.04 | 2.39 | ✅ 支持（需验证 t64 依赖） |
| Ubuntu 20.04 | 2.31 | ⚠️ 低于 2.32，不承诺 |
| Debian 11 bullseye | 2.31 | ⚠️ 低于 2.32，不承诺 |
| RHEL 9 / Rocky 9 / Alma 9 | 2.34 | ✅ 支持 |
| RHEL 10 / Rocky 10 / Alma 10 | 2.39 | ✅ 支持 |
| RHEL 8 / CentOS 8 | 2.28 | ⛔ 不支持 |
| Fedora 41/42/43 | ≥ 2.40 | ✅ 支持 |
| openSUSE Leap 15.6 / SLES 15 SP6 | 2.38 | ✅ 支持 |
| Arch / Tumbleweed | 滚动最新 | ✅ 支持 |
| Alpine | musl | ⛔ 不支持（见 §3.5） |

注意：上表是“按 glibc 版本”的初步判断，不等于已在每个发行版上完成 GUI 验收；发布前
仍需在目标镜像做安装 + 启动测试。Ubuntu 24.04 的 t64 包已实测提供旧名
（见 §3.1），但 Debian 13/arm64 仍应以 `apt install ./...deb` 的实际结果为准。

### 4.3 Flatpak runtime 24.08 与 Snap base core24

| 项目 | 当前/建议 | 说明 |
|---|---|---|
| Flatpak runtime | `org.freedesktop.Platform//24.08`（**EOL 2026/09**） | 需升级到 25.08/26.08；先确认 Electron BaseApp 分支 |
| Flatpak BaseApp | `org.electronjs.Electron2.BaseApp//24.08` | 提供 Electron 所需基础库与 zypak；版本必须与 runtime 对齐 |
| Flatpak SDK | `org.freedesktop.Sdk//24.08` | 仅构建期使用；同样需升级 |
| Snap base | `core24`（Ubuntu 24.04，glibc 2.39） | 当前受支持；Ubuntu 26.04 后规划 `core26` |
| Snap 构建 | `snapcraft`（LXD/VM） | Docker 内无 snapd/systemd，不能做有效安装验证 |

Flatpak 的 Electron 打包规范见
[Flatpak docs: Electron](https://docs.flatpak.org/en/latest/electron.html)：Freedesktop
runtime + Electron BaseApp + zypak wrapper 是标准组合；文档建议默认 `--socket=x11`，
Wayland 通过 `--ozone-platform-hint=auto` 由用户选择。本项目 patch 中设置了
`useWaylandFlags: true`，与“默认 X11、Wayland 实验性”的官方建议存在偏差，建议在
Wayland 真机验收前改回更保守的默认，或明确标注实验性。

### 4.4 Arch：系统 Electron 不可用

这是最容易踩的坑。ArchWiki 的 Electron 指南明确：

> Applications that require `ELECTRON_RUN_AS_NODE=1`, e.g. Visual Studio Code,
> cannot use `/usr/bin/electron*`.

本项目 `apps/desktop` 的 Host 通过 `ELECTRON_RUN_AS_NODE` 启动，因此：

- **不要**在 PKGBUILD 中 `depends=('electron')` 然后 wrapper 调 `/usr/bin/electron`；
- **必须**把 Electron 44 运行时随包安装到 `/opt/deepseek-harness`；
- 如果未来改成“纯 GUI、不需要 RunAsNode”的架构，才可以考虑系统 Electron，但那是
  产品架构变更，不是打包优化。

同理适用于任何“用系统 Electron 减小体积”的想法：先确认是否需要 RunAsNode、原生模块
ABI 是否匹配。

### 4.5 Alpine：musl 与 glibc 的硬不兼容

再强调一次，因为这是最容易被误判为“加个包就行”的部分：

- 官方 Electron 是 glibc 二进制；Alpine 是 musl；
- `gcompat` 不是完整 glibc 兼容层，Electron/Chromium 的动态加载、符号版本、NSS、
  sandbox 都可能失败；
- Alpine 的 `electron` 包是**另一条构建线**（musl 源码重建），版本 42.11.18，位于
  `testing`，与本项目 Electron 44 不匹配；
- 本项目还内置 glibc 的 Node/Python/原生模块，不能只替换 Electron。

**结论：Alpine 不支持；不要发布 apk 包。** 如果用户需要 Alpine，建议使用 dsh CLI
（如果上游提供）或容器化方案，而不是桌面 App。

### 4.6 Nix derivation 的取舍

- **包装 AppImage**：最快，适合 flake/overlay 自用；缺点是“二进制再包装”，Nix 社区
  通常不接受进 nixpkgs 主树，且更新要改 hash。
- **原生 derivation**：从 `linux-unpacked` 出发，`autoPatchelfHook` 处理 ELF，
  `makeWrapper` 注入环境；更可维护，但需要处理 setuid sandbox、RPATH、Python 路径。
- **从源码构建**：`buildNpmPackage`/`fetchNpmDeps` + pnpm 离线缓存 + Python/原生模块，
  最“Nix 原生”，但工作量最大，且上游构建脚本与 Nix 沙箱的兼容性未知。

建议先用 `appimageTools.wrapType2` 做 PoC，验证 GUI/Agent 能力，再决定是否投入原生
derivation；不要一开始就追求进 nixpkgs。

### 4.7 “从 AppImage 重打包” vs “原生 Electron 构建”

| 维度 | 从 AppImage/deb 重打包 | 原生 Electron 构建 |
|---|---|---|
| 工作量 | 低（2–5 人日） | 高（5–15 人日） |
| 复用已验证产物 | ✅ | ⚠️ 需重新验证 |
| 发行版审核接受度 | AUR `-bin` 可；Gentoo/Nix 主树较难 | 更高 |
| 更新/重建 | 跟随上游产物 | 跟随源码/依赖 |
| 体积 | 与 AppImage 相同 | 可裁剪 |
| 风险 | 解包路径、desktop 文件、setuid 权限 | 构建链、原生模块、Electron 版本锁定 |

建议：**Tier 2/3 先用重打包验证需求**（AUR `-bin`、Gentoo overlay、Nix wrapper），
只有当某个渠道证明有稳定用户量后，再投入原生构建。

### 4.8 沙箱与产品能力的结构性矛盾

dsh 是本地 Agent，需要执行 shell、读写工作区、启动本地服务、安装插件。Flatpak/Snap
的强沙箱与“最小权限”商店政策天然冲突：

- Flatpak：需要 `--filesystem=home`（甚至 host）与 `--share=network`；Flathub 对宽权限
  审查严格，开发工具类还可能被直接劝退。
- Snap：strict 下 `home` 不含隐藏文件，`personal-files` 需声明；完整能力通常要 classic，
  而 classic 需 Store 批准。

因此，**deb/rpm/AppImage 是功能最完整的渠道；Flatpak/Snap 应定位为“受限模式/试用”**，
并在文档中明确权限差异。不要为了上商店而牺牲核心能力，也不要在商店版本中静默降级。

### 4.9 签名与更新：当前是空白

- 现有 `SHA256SUMS` + 测试 GPG 签名只证明机制可用，**不是发布签名**；
- 没有 `electron-updater` 的 Linux 接入，也没有自建更新服务器；
- 各渠道的原生更新能力不同：APT/DNF/Zypper/pacman/apk/emerge/nix 各有仓库机制；
  Flatpak 有 OSTree；Snap 有 Store refresh；AppImage 有 zsync。

建议按渠道分工，而不是做一个“万能 updater”：

| 渠道 | 更新方式 | 签名 |
|---|---|---|
| deb | 自建 APT 仓库 | `Release.gpg` / `InRelease` |
| rpm | 自建 DNF 仓库 | `repomd.xml.asc` + `rpmsign` |
| AppImage | 手动/字节级 zsync | 嵌入式 GPG + `SHA256SUMS.asc` |
| Flatpak | 自建 OSTree 或 Flathub | OSTree commit + repo GPG |
| Snap | Store refresh | Store 签名 |
| Arch/AUR | pacman/AUR helper | `makepkg --sign` / PGP |
| Nix | 二进制缓存/flake | `nix sign-paths` / cache key |

---

## 5. 验证与 CI 矩阵

原则：

1. **结构检查**（元数据、依赖、文件权限）在容器里做，快且可重复；
2. **安装 + 启动**必须在目标发行版镜像中做；GUI 用 Xvfb，但 Flatpak/Snap 的沙箱
   行为在 Docker 中不可靠，需 VM/真机；
3. 每个格式都要有“负向检查”：缺依赖、错误架构、未签名、EOL runtime 应被拒绝；
4. 所有 artifact 的 SHA-256 进入 `SHA256SUMS`，发布时再用离线 GPG 签。

| 格式 | 建议镜像 | 关键命令 | 通过标准 | 备注 |
|---|---|---|---|---|
| deb | `debian:12`, `debian:13`, `ubuntu:22.04`, `ubuntu:24.04` | `dpkg-deb -I`, `lintian --fail-on error`, `apt-get install -y ./pkg.deb`, `deepseek-harness --version`（或启动） | 依赖可解析、安装成功、Xvfb 启动、无 missing lib | t64 包名必须实测；`lintian` 先设基线 |
| rpm | `fedora:41`, `fedora:42`, `rockylinux:9`, `almalinux:9`, `opensuse/leap:15.6` | `rpm -qpi`, `rpm -qpR`, `rpmlint`, `dnf install -y ./pkg.rpm`, 启动 | 依赖可解析、安装成功、SELinux 无致命拒绝、启动 | RHEL 8 明确不测/不支持；openSUSE 用 zypper |
| AppImage | `ubuntu:22.04`, `ubuntu:24.04`, `fedora:42`, `archlinux:base` | `chmod +x`, `./app --appimage-extract-and-run`, `--appimage-extract`, `ldd` 检查 | 可执行、窗口启动、无 missing lib | FUSE 不可用时用 extract-and-run；userns 限制单独验证 |
| Flatpak | `ubuntu:24.04` + flatpak；真实主机/VM | `flatpak-builder --repo`, `flatpak build-import-bundle`, `flatpak install --user`, `flatpak run`, `flatpak-builder-lint`, `appstreamcli validate` | 安装、启动、权限符合预期、runtime 非 EOL | Docker 内 bwrap seccomp 受限，GUI 需真机 |
| Snap | Ubuntu 24.04 VM/LXD（非 Docker） | `snapcraft pack`, `snapcraft lint`, `snap install --dangerous`, `snap connections`, `snap run` | 安装、启动、文件/网络权限符合预期、refresh 不丢数据 | Docker 无 snapd/systemd，不可作为验证 |
| Arch | `archlinux:base-devel` | `makepkg -si --noconfirm`, `namcap PKGBUILD`, `namcap *.pkg.tar.zst`, `pacman -Qip` | 构建、安装、启动、依赖完整 | 系统 Electron 不可用；注意 setuid |
| Alpine | `alpine:edge` | `abuild -r`, `abuild-sign`, `apk add --allow-untrusted`, `ldd` | **预期失败**：glibc Electron 无法加载 | 仅用于记录“不支持”的证据，不发布 |
| Gentoo | `gentoo/stage3` | `ebuild *.ebuild manifest`, `pkgcheck scan`, `emerge --ask` | 构建、安装、启动 | 需要 overlay；主树审核不确定 |
| Nix | `nixos/nix` | `nix-build`, `nix flake check`, `nix run`, `nixpkgs-review` | 构建、启动、无 RPATH/解释器错误 | 只读 store 与 sandbox 需特别验证 |
| OBS | OBS worker（远程） | `osc build`, `osc results`, `osc submitreq` | 所有仓库/架构构建成功、仓库签名可验证 | 构建期无网络，依赖需 vendor |

补充命令（本地静态检查）：

```bash
# 所有 shell 脚本语法检查（不改变代码）
bash -n scripts/*.sh

# 现有产物校验
scripts/verify-artifacts.sh

# 发布签名（需要真实 release key）
DSHD_GPG_KEY=<release-fingerprint> scripts/sign-artifacts.sh
```

CI 落地建议：

- 用 GitHub Actions matrix 跑 deb/rpm/AppImage 的“安装 + Xvfb 启动”；
- Flatpak 用 `flatpak-builder` 做构建/lint，GUI 放到 self-hosted runner 或人工验收；
- Snap 用 LXD/VM job，不要在 Docker 里假装验证；
- 每次发布把 `SHA256SUMS`、各格式元数据输出、lint 结果归档到 `evidence/`；
- 对 EOL runtime（当前 Flatpak 24.08）加一条“拒绝发布”的检查。

---

## 6. 分层建议与实施路线

### 6.1 Tier 划分

| Tier | 格式 / 渠道 | 定位 | 理由 |
|---|---|---|---|
| **Tier 1（已交付，持续维护）** | deb、rpm、AppImage、Flatpak bundle | 主发布渠道 | 已产出并验证；覆盖 Debian/Ubuntu、Fedora/RHEL、跨发行版下载、沙箱用户；无需新工具链 |
| **Tier 2（优先补齐）** | Snap、Arch/AUR、openSUSE OBS | 增量覆盖与开发者渠道 | Snap 触达 Ubuntu 预装用户；Arch 影响开发者口碑；OBS 一次投入可产 rpm/deb/AppImage 并服务 openSUSE/SLES |
| **Tier 3（机会性/社区驱动）** | Gentoo、NixOS；Alpine 明确不支持 | 长尾与生态完整性 | Gentoo/Nix 用户少但粘性高，适合 overlay/flake 先做；Alpine 受 musl 硬阻塞，投入产出比极低 |

**Tier 1 的维护重点不是“再加格式”，而是补齐发布质量：**

1. 真实发布 GPG 签名（`SHA256SUMS.asc`、deb/rpm 签名）；
2. 在 Debian 12/13、Ubuntu 22.04/24.04、Fedora 41/42、Rocky 9 上做安装+启动矩阵；
3. Flatpak runtime 从 24.08 升级到受支持分支，并决定“自建仓库 vs Flathub”；
4. 明确 glibc 支持基线，在下载页/文档中写清楚；
5. 评估 Wayland/托盘/输入法，不要用 `--no-sandbox` 掩盖 sandbox 问题。

### 6.2 分阶段计划

**P0（1–2 周）：发布卫生与支持矩阵**

- 产出真实发布签名与校验说明；
- 在 4–6 个目标镜像上跑 deb/rpm/AppImage 安装+启动；
- 修复 t64 依赖、rpm 弱依赖、desktop 文件等已知问题；
- 确定 Flatpak 24.08 的处置：升级或明确“内部临时产物”；
- 在 README/下载页写清“支持/不支持”的发行版列表。

**退出标准**：`SHA256SUMS.asc` 可验证；目标矩阵全绿；文档不再暗示 Flatpak 可上 Flathub。

**P1（2–6 周）：Tier 2 PoC**

- **Snap**：用 electron-builder `snap` target 或最小 `snapcraft.yaml` 做 core24 PoC；
  先 strict，记录哪些能力不可用；再评估 classic 申请是否值得。
- **Arch**：发布 AUR `deepseek-harness-bin`，从 AppImage 重打包；`namcap` 清零可修项；
  收集 issue，验证更新频率。
- **openSUSE OBS**：建 `home:` 项目，spec + `_service`，产 rpm 并用 zypper 安装；
  验证 OBS 签名与 arm64 worker。

**退出标准**：三个渠道各有一个可重复构建、可安装启动的产物；有明确的维护人/节奏；
Snap 的权限结论（strict 够不够、是否申请 classic）有书面结论。

**P2（6–12 周）：深化与取舍**

- 若 Snap 需求成立，推进 Store 审核/classic；否则降级为“不发布”；
- 若 Arch 用户量成立，评估原生 PKGBUILD（不依赖系统 Electron）；
- 若 Flathub 是战略目标，单独立项做源码化 manifest、权限模型、AppStream 元数据；
  否则把 Flatpak 定位为自建仓库；
- Nix flake（先 `appimageTools` 包装）作为社区贡献，不阻塞主线。

**P3（机会性）**：

- Gentoo overlay ebuild；
- Alpine 仅在“上游提供 musl Electron 构建”时重新评估；
- 社区维护的 AUR/Nix/Gentoo 包进入官方仓库的提名。

### 6.3 不建议做的事

- ❌ 为 Alpine 发布 apk 包（装得上、跑不起来，伤害信任）；
- ❌ 用 Arch 系统 Electron 替换自带运行时（`ELECTRON_RUN_AS_NODE` 直接不成立）；
- ❌ 把 Flatpak bundle 直接传 Flathub（预编译二进制 + EOL runtime，必被拒）；
- ❌ 在没有发布签名/更新校验的情况下做自动更新；
- ❌ 为了“支持更多格式”而复制多套构建逻辑，导致版本漂移。

---

## 7. 风险登记

| # | 风险 | 影响 | 可能性 | 缓解 |
|---|---|---|---|---|
| 1 | Flatpak 24.08 EOL | 安全更新缺失、Flathub 拒绝、未来无法安装 | 高（已发生） | 升级 25.08/26.08；先确认 Electron BaseApp 分支；升级前冻结发布 |
| 2 | Alpine musl 不兼容 | 用户安装后无法启动 | 确定 | 明确不支持；文档给出原因与替代方案 |
| 3 | Arch 系统 Electron 误用 | Host 无法启动 | 中 | 包内自带 Electron；PKGBUILD 不依赖 `electron` |
| 4 | RHEL 8 / Debian 11 / Ubuntu 20.04 glibc 过低 | 启动/语音模块崩溃 | 高 | 声明 glibc ≥ 2.32；下载页标注支持矩阵 |
| 5 | Ubuntu 24.04 t64 依赖不满足 | `apt install` 失败 | 中 | 在 noble 镜像实测；必要时改 `Depends` 或加替代依赖 |
| 6 | Snap strict 权限不足 | 核心功能不可用 | 高 | 先 PoC 列明缺口；必要时申请 classic；否则不发布 |
| 7 | Flathub 源码构建/权限审核 | 无法上架，投入浪费 | 高 | 先自建仓库；Flathub 单独立项，不与管理层承诺绑定 |
| 8 | 无发布签名/更新 | 供应链风险、用户无法安全升级 | 高 | P0 完成 GPG 签名；按渠道接原生仓库更新 |
| 9 | AppImage 在 Ubuntu 24.04 sandbox 失败 | 启动失败或被迫 `--no-sandbox` | 中 | 真机验证 userns；提供 deb 作为替代；不默认关闭 sandbox |
| 10 | Electron 版本锁定 44.7.0 | 安全更新/ABI 跟进成本 | 中 | 建立 Electron 升级 checklist；各格式重新验证 |
| 11 | Flatpak Wayland 默认与官方建议不一致 | Wayland 会话不稳定 | 中 | 默认 X11/XWayland；Wayland 标注实验性并真机验收 |
| 12 | rpm 无 `libsecret`/`libappindicator` 弱依赖 | 密钥环/托盘功能缺失 | 中 | spec 补 `Requires`/`Recommends`；文档说明 |

---

## 8. 参考链接

### 通用 / Electron

- [Electron v44.7.0 README（平台支持与预编译二进制）](https://github.com/electron/electron/blob/v44.7.0/README.md)
- [Electron release timelines](https://www.electronjs.org/docs/latest/tutorial/electron-timelines)
- [Electron 安装/镜像](https://www.electronjs.org/docs/latest/tutorial/installation)

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
- [Freedesktop SDK release timeline（24.08 EOL）](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Releases)
- [AppImage packaging guide](https://docs.appimage.org/packaging-guide/index.html)
- [AppImage: signing](https://docs.appimage.org/packaging-guide/optional/signatures.html)
- [AppImage: updates](https://docs.appimage.org/packaging-guide/optional/updates.html)

### 仓库内文档

- [architecture.md](architecture.md)
- [release.md](release.md)
- [testing.md](testing.md)
- [research/official-desktop-audit.md](research/official-desktop-audit.md)
- [../README.md](../README.md)
