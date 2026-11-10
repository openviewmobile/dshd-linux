# Linux 架构

## 范围

Linux x64/arm64 桌面 App，基于官方 `apps/desktop`（Electron）增加 Linux 构建与发布目标。
不是重写 UI，也不是另做一个 Web 壳；目标是让官方桌面壳在 Linux 上产出可安装包并通过
Xvfb 冒烟。

## 为什么是补丁而不是 fork

官方 Desktop 已内置 linux-x64/linux-arm64 的 primary runtime（Node 24、Python、pnpm 等），
electron-builder 也有 Linux AppImage target；但发布目标只列 macOS/Windows，Linux 被
`desktop-build-paths.mjs` 和 `package-target.ts` 排除。项目因此维护三个可审查补丁：

| 补丁 | 作用 |
|---|---|
| `0001-linux-desktop-target.patch` | 注册 Linux target、Electron 路径、打包/冒烟脚本 |
| `0002-linux-deb-rpm-flatpak.patch` | 增加 deb/rpm/Flatpak target 与 Flatpak 配置 |
| `0003-primary-runtime-mirrors.patch` | primary runtime 走 npmmirror，减少 nodejs.org/GitHub 依赖 |

补丁只改构建/发布路径，不替换 dsh 内核或前端。上游移动后补丁可能需要重做。

## 构建链路

```
Dockerfile (node:24-bookworm + Xvfb + flatpak/rpm)
  └─ /src: 上游 deepseek-harness 克隆
       ├─ git apply patches/
       ├─ pnpm install --frozen-lockfile
       └─ pnpm --filter @deepseek-ai/dsh-desktop package:linux:<arch>
            └─ .desktop-build/targets/linux-<arch>/unsigned-artifacts/
                 AppImage / deb / rpm / flatpak
```

`build-and-smoke.sh` 只构建 `--dir` unpacked 包并在 Xvfb 中启动；`package-formats.sh`
生成安装包；`build-flatpak-x64.sh` 在预置 SDK 镜像中重建 x64 全格式并把产物取回
`dist/linux-x64/`。

## 运行时

- Electron 壳启动内置 Node 的 `dsh web`，解析 token URL 后加载同一套 dsh Web UI；
- 内置 Node 24 / pnpm / Python / ripgrep；`koffi`、`sharp`、`node-pty`、`grep`、`glob`
  在 packaged smoke 中为 true；
- Linux 上 Electron 需要 `--no-sandbox`（容器测试）；正式发行按要求配置 sandbox；
- Office→PDF 缺少 Linux 原生 LibreOfficeKit，v1 显式跳过。

## 已知架构限制

- 上游没有官方 Linux 发布验收；补丁需要跟随上游变化。
- 自动更新、代码签名、公证尚未接入；v1 为 unsigned 包 + 手动/自有更新。
- Wayland、托盘、输入法、桌面集成尚未系统验证。
