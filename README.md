# DSHD for Linux（独立项目）

本目录是一个可单独复制、构建和测试的 Linux 桌面发行版项目：在官方
`apps/desktop` 上增加 Linux x64/arm64 目标，并用 Docker + Xvfb 做可重复的打包/冒烟。

- 补丁：`patches/`（Linux target、deb/rpm/Flatpak、运行时镜像）；
- 构建：`Dockerfile` + `scripts/`；
- 产物：AppImage / deb / rpm / Flatpak；
- 证据：`evidence/`。

## 目录

```
Dockerfile              构建/测试镜像
patches/                Linux target 与打包补丁
scripts/                构建、打包、冒烟、签名与校验
evidence/               Xvfb/GUI/产物证据
dist/                   本地产物（gitignore）
```

## 快速开始

```bash
# 在项目根目录
docker build -f Dockerfile -t dshd-linux-test .
docker volume create dshd-linux-src
docker run --rm -it -v "$PWD:/work" -v dshd-linux-src:/src dshd-linux-test
# 容器内
/work/scripts/build-and-smoke.sh
```

产物格式和平台限制见下方“Linux 安装包格式”和“已知风险”。

目标：在官方 `apps/desktop` 基础上增加 **Linux x64/arm64 桌面发行版**，功能与 macOS/Windows 桌面端对齐；用 Docker 做可重复的构建/运行测试。

## 当前发现

- 官方 Desktop 已内置 **linux-x64 / linux-arm64** 的 primary runtime（Node 24、Python、pnpm、Office 依赖），见 `scripts/primary-runtime/lock.json`。
- 官方 `electron-builder` 配置已有 `linux: { target: ['AppImage'] }`。
- 但官方发布目标只列 `mac-arm64`、`mac-x64`、`win-x64`；Linux 被 `desktop-build-paths.mjs` 和 `package-target.ts` 明确排除。
- 因此 Linux 不是“从零移植”，而是**把已有的运行时/打包能力接到发布目标上**，再补：
  - Linux 目标注册；
  - 打包/冒烟路径；
  - Docker GUI 测试；
  - updater/签名策略（v1 先 unsigned）。

## 实机结果（2026-11-08）

**已在 Docker（`node:24-bookworm` / linux-arm64）+ Xvfb 中构建并启动 `linux-arm64` 桌面 App。**

- 构建命令：`pnpm --filter @deepseek-ai/dsh-desktop package:linux:arm64:dir`
- 产物：`.desktop-build/targets/linux-arm64/unsigned-artifacts/linux-arm64-unpacked/`
- 启动：`./deepseek-harness --no-sandbox --disable-gpu`（Xvfb 1440×900）
- 结果：欢迎页正常渲染，见 [evidence/linux-welcome.png](evidence/linux-welcome.png)。
- AppImage 也已构建并同样启动验证：`deepseek-harness-0.2.2-rc.1-linux-arm64-unsigned.AppImage`（350 MB），见 [evidence/linux-appimage.png](evidence/linux-appimage.png)。
- 本机可交付副本（已 gitignore）：`dist/linux-arm64/`，含 `SHA256SUMS`；SHA-256 `c93e1a4e9a8a67fe8f4d03e344911ac6bc1687acd7026a57f45cb2da2d4ec00d`。
- Packaged runtime smoke 通过：`node 24.21.0`、`koffi`、`sharp`、`pty`、`pnpm`、`grep`、`glob` 均为 true；`dsh web` 能打印 token URL。
- **限制**：上游没有 `libreoffice-kit-linux-arm64-glibc` 原生包，Office→PDF 在 Linux 上跳过；打包 smoke 已显式记录该 gap。v1 Linux 先不承诺 Office 导出。

> AppImage 在容器内用 `--appimage-extract-and-run --no-sandbox` 验证；正式分发建议在目标发行版上直接双击/`chmod +x` 后运行。

> 这次验证说明 Linux 不是“改一行配置”：需要补目标注册、Electron 路径、打包/冒烟路径、record target 和类型声明；补丁已覆盖这些点。

## 与 macOS/Windows 桌面端的对齐度

| 能力 | Linux 状态 |
|---|---|
| Electron 壳、Host 启动、token→cookie、Web UI | ✅ 已启动截图 |
| 内置 Node 24 / pnpm / Python / ripgrep | ✅ packaged smoke |
| `koffi` / `sharp` / `node-pty` / `grep` / `glob` | ✅ true |
| 首启欢迎页、Sign in / Add API Key | ✅ 已渲染；未做真实供应商 E2E |
| 插件安装/启用/卸载 | ✅ deb GUI 实测（whale pet） |
| 自动更新 / 签名 / 公证 | ❌ v1 无；unsigned AppImage |
| Office→PDF | ❌ 缺 Linux 原生 LibreOfficeKit；会显式跳过 |
| 托盘 / Wayland / 输入法 / 桌面集成 | ⏳ 未验证；`desktopName` 警告待修 |
| x86_64 产物 | ⏳ 需在 x64 Linux 主机构建（脚本已支持） |


## Linux 安装包格式（AppImage / deb / rpm / Flatpak）

`patches/0002-linux-deb-rpm-flatpak.patch` 在 Linux 目标上追加：

```js
linux: {
  target: ['AppImage', 'deb', 'rpm', 'flatpak'],
},
flatpak: {
  runtimeVersion: '24.08',
  baseVersion: '24.08',
  useWaylandFlags: true,
},
```

应用顺序：

```bash
git apply patches/0001-linux-desktop-target.patch
git apply patches/0002-linux-deb-rpm-flatpak.patch
pnpm --filter @deepseek-ai/dsh-desktop package:linux:arm64   # 或 linux:x64
```

产物在 `.desktop-build/targets/linux-<arch>/unsigned-artifacts/`：

| 格式 | 产物 | 安装/运行 |
|---|---|---|
| AppImage | `...AppImage` | `chmod +x` 后直接运行 |
| deb | `...deb` | `sudo apt install ./...deb` |
| rpm | `...rpm` | `sudo dnf install ./...rpm` |
| Flatpak | `...flatpak` | `flatpak install --user ./...flatpak` |
| Flatpak x64 | 239 MB | `flatpak install --user` 成功；GUI 需真机 |

**2026-11-08 arm64 实测**（Docker `dshd-linux-test:flatpak`）：

| 格式 | 大小 | 验证 |
|---|---|---|
| deb | 262 MB | `dpkg-deb -I`：Package `deepseek-harness`、Architecture `arm64`、Depends/Maintainer/Homepage 正常 |
| rpm | 216 MB | `rpm -qpi`：Name `deepseek-harness`、Architecture `aarch64`、License/URL 正常 |
| Flatpak | 226 MB | `flatpak install --user --no-deps` 成功；`flatpak run --command=sh ...` 沙箱执行成功 |
| AppImage | 349 MB | 既有 Xvfb 启动验证 |

SHA-256 见 [dist/linux-arm64/SHA256SUMS](dist/linux-arm64/SHA256SUMS)（本机产物目录已 gitignore）。

> Docker 内安装/校验 Flatpak runtime 需要 `--privileged`（bubblewrap 创建 namespace）；普通 Linux 桌面不需要。首次构建 Flatpak 会从 Flathub 下载 `org.freedesktop.Platform` / `Sdk` / `Electron2.BaseApp` 24.08，约数 GB。

Flatpak 由 electron-builder 26 的 `flatpak` target + `@malept/flatpak-bundler` 生成；构建机需要 `flatpak`、`flatpak-builder` 和 Flathub remote。Dockerfile 已包含这些依赖。Flatpak target 会按 `flatpak.runtimeVersion/baseVersion` 自动安装 `org.freedesktop.Platform`、`org.freedesktop.Sdk`、`org.electronjs.Electron2.BaseApp` 24.08；首次构建需要较大下载。

> deb/rpm 依赖 electron-builder 的 fpm 工具链；Flatpak 包是单文件 bundle，适合手动 `flatpak install`，尚未提交 Flathub。v1 仍 unsigned。

## 补丁

`patches/0001-linux-desktop-target.patch` 增加：

- `linux-x64`、`linux-arm64` 构建目标；
- `package:linux:*` 脚本；
- Linux unsigned 本地环境；
- Linux Electron 路径；
- Linux packaged smoke 路径；
- Linux 跳过 macOS/Windows 专有签名/策略。

应用方式：

```bash
git clone --depth 1 https://github.com/deepseek-ai/deepseek-harness.git /src
cd /src
git apply /work/patches/0001-linux-desktop-target.patch
git apply /work/patches/0002-linux-deb-rpm-flatpak.patch
```

## Docker 测试

```bash
# 在项目根目录执行
docker build -f Dockerfile -t dshd-linux-test .
docker volume create dshd-linux-src

docker run --rm -it \
  -v "$PWD:/work" \
  -v dshd-linux-src:/src \
  dshd-linux-test
```

容器内：

```bash
/work/scripts/build-and-smoke.sh
```

> 必须把 `/src` 放在 Docker named volume 里；macOS bind mount（如 `/tmp`）在 electron-builder 复制 Windows `node.cmd` 时会触发 `EACCES: permission denied, chmod`。

脚本会：

1. clone/更新上游到 `/src`；
2. 应用补丁；
3. `pnpm install`；
4. `pnpm --filter @deepseek-ai/dsh-desktop package:linux:arm64:dir`（arm64 主机；`linux-x64` 同理）；
5. 在 Xvfb 中启动 `linux-arm64-unpacked/deepseek-harness --no-sandbox`；
6. 截图并检查窗口/日志。

生成 deb/rpm/Flatpak（不是 `--dir` 冒烟包）：

```bash
/work/scripts/package-formats.sh
```

## 已知风险

- 首次 `pnpm install` 需要下载 Electron/Node/Python wheels，耗时较长。
- Docker 内 Electron 需要 `--no-sandbox`；仅测试用。
- Linux 更新器/签名未做；v1 为 unsigned AppImage/deb/rpm/Flatpak + 手动更新/自有 updater。
- 官方 Desktop 的 Linux 代码路径存在，但没有官方发布验收，需要逐项补测试。

## x64 构建（2026-11-08）

Dockerfile 已参数化，可用国内源在 arm64 主机上构建 x86_64 工具链：

```bash
docker build --platform linux/amd64 \
  --build-arg NODE_IMAGE=node:24-bookworm-slim-amd64 \
  --build-arg APT_MIRROR=http://mirrors.aliyun.com \
  --build-arg NPM_REGISTRY=https://registry.npmmirror.com \
  -t dshd-linux-test:amd64 -f Dockerfile .
```

x64 依赖重装、Host/Desktop/Client/Web 构建门禁（10/10）、x64 Electron 和 primary
runtime 均已通过；primary runtime 的 Node/Python 资产默认走 npmmirror（补丁 0003），
不再依赖 nodejs.org/GitHub。已产出 x64 AppImage/deb/rpm/Flatpak。deb 在 amd64 Docker + Xvfb 中安装启动，
窗口与本地 Host 正常；Flatpak bundle 安装验证通过，GUI 需真机（Docker 内 bwrap
受 seccomp 限制）。

```bash
pnpm --filter @deepseek-ai/dsh-desktop package:linux:x64
```

x64 Flatpak：239 MiB，SHA-256 `74b27f86…`，安装后 ref 为
`com.deepseek.harness/x86_64/master`、runtime 为
`org.freedesktop.Platform/x86_64/24.08`；详见
[evidence/x64-flatpak.txt](evidence/x64-flatpak.txt)。构建时容器 HTTPS 走宿主机
CONNECT 代理，解决 Docker NAT 下载慢的问题。

重复 GUI 冒烟：

```bash
scripts/smoke-deb-x64.sh
```

它会安装 x64 deb、启动 Xvfb、拉起 Electron 并截图到
`evidence/deb-x64-smoke.png`。记录与截图见
[evidence/x64-artifacts.txt](evidence/x64-artifacts.txt)、
[evidence/linux-x64-gui.png](evidence/linux-x64-gui.png)。

## GUI 冒烟

```bash
scripts/smoke-flatpak-x64.sh
```

脚本安装 Flatpak bundle，启动 Xvfb + dbus，验证窗口和 `dsh web:` 日志，并输出
`evidence/flatpak-x64-smoke.png`。它只为 Docker 测试服务，不能作为发行版补丁。

## x64 全格式重建

```bash
scripts/build-flatpak-x64.sh
```

脚本会在宿主机启动 CONNECT 代理，让 Docker 内的 Flathub/Electron 下载走宿主机网络，
然后运行 `package:linux:x64` 并把 AppImage/deb/rpm/Flatpak + `SHA256SUMS` 取回 `dist/linux-x64`。
需要预置好 `dshd-linux-test:flatpak-sdk` 镜像和 `dshd-linux-x64-src` 卷。

## 校验与签名

```bash
scripts/verify-artifacts.sh
DSHD_GPG_KEY=<release-fingerprint> scripts/sign-artifacts.sh
```

`SHA256SUMS` 覆盖 AppImage/deb/rpm/Flatpak；签名脚本需要发布者 GPG 密钥。仓库里的
`evidence/SHA256SUMS.asc.test` 只是测试签名，不是发布签名。
