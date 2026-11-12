# V2EX（分享创造）

标题：

```text
给官方 DeepSeek Harness 桌面端补上 Linux 发行版级打包（AppImage/deb/rpm/Flatpak）
```

正文：

```text
官方 DeepSeek Harness 桌面端目前只发 macOS/Windows，Linux 用户要么用 Web，要么自己从源码编。我做了个下游打包项目：不改 agent 内核，保留官方 Electron 桌面，把 Linux 侧“能下载、能装、能验证”补齐。

目前提供：
- x86_64 / aarch64 的 AppImage、deb、rpm、Flatpak
- APT / DNF 仓库（x86_64，GitHub Pages）
- 每个文件独立 GPG 签名、SHA256SUMS、SBOM、GitHub build provenance
- 本地 DOCX/XLSX/PPTX -> PDF（WASM）
- 全部由 GitHub Actions 构建和签名

需要说明：
- 这是社区项目，不是官方 DeepSeek 发布
- 还是 RC；真实 Wayland/KDE/GNOME 测试还没做
- AppImage 自动更新已经有 feed，但版本 A -> B 的完整验收还没做
- Flathub/AUR 还没正式发布
- 文件名里的 unsigned 指没有平台代码签名证书，不是没有 GPG 签名

Release:
https://github.com/openviewmobile/dshd-linux/releases/tag/v0.2.2-rc.1.3

想优先听 Debian/Fedora/Arch 用户的意见：包名、依赖、安装路径、FUSE/沙箱、以及 apt/dnf 仓库是否真的有用。
```

节点：`分享创造`。避免纯链接帖，正文里给出限制和验证方式。
