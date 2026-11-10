# Linux 发布

> 发行版/包格式的完整矩阵、分层建议与技术约束见
> [distro-packages.md](distro-packages.md)。当前**只产出**了 AppImage / deb / rpm /
> Flatpak（rpm 目前仅做元数据检查）；Snap、Arch/AUR、openSUSE OBS 是计划项，
> Alpine 因 musl 与 Electron 官方 glibc 二进制不兼容而明确不支持。

## 产物

`package-formats.sh` / `package:linux:<arch>` 生成：

| 格式 | 用途 |
|---|---|
| AppImage | 单文件，`chmod +x` 后运行 |
| deb | Debian/Ubuntu 安装 |
| rpm | Fedora/RHEL 安装 |
| Flatpak | 单文件 bundle，手动 `flatpak install` |

arm64 与 x64 均已产出；x64 产物在 `dist/linux-x64/`，包含 `SHA256SUMS`。

## 构建

```bash
docker build -f Dockerfile -t dshd-linux-test .
docker run --rm -it -v "$PWD:/work" -v dshd-linux-src:/src dshd-linux-test
# 容器内
/work/scripts/package-formats.sh
```

x64 全格式重建：

```bash
scripts/build-flatpak-x64.sh
```

需要预置 `dshd-linux-test:flatpak-sdk` 镜像和 `dshd-linux-x64-src` 卷；脚本在宿主机
启动 CONNECT 代理以加速 Flathub/Electron 下载。

## 签名与校验

```bash
scripts/verify-artifacts.sh
DSHD_GPG_KEY=<release-fingerprint> scripts/sign-artifacts.sh
```

`SHA256SUMS` 覆盖所有安装包；`evidence/SHA256SUMS.asc.test` 只是测试签名，不是发布签名。

## 更新与分发

- v1 是 unsigned 包，没有自动更新器；需要手动下载或自有 updater。
- 正式发布应提供 GPG 签名、HTTPS 下载页和版本说明。
- 不上架应用商店；通过 GitHub Releases/官网分发。
- Flatpak runtime 当前为 24.08，但该分支已于 2026-09 EOL；在升级到 25.08/26.08
  之前，Flatpak 只能作为内部/临时产物。系统依赖按 Electron 与目标 runtime 要求执行。

## 发行版支持分层

| 层级 | 渠道 | 状态 |
|---|---|---|
| Tier 1 | deb、rpm、AppImage、Flatpak bundle | 已产出；deb/AppImage/Flatpak 有启动验证，rpm 仅元数据 |
| Tier 2 | Snap、Arch/AUR、openSUSE OBS | 研究/计划，尚未产出 |
| Tier 3 | Gentoo、Nix | 机会性/社区驱动 |
| 不支持 | Alpine（musl） | Electron 官方二进制为 glibc，无法直接运行 |

完整矩阵、工作量估算和 CI 验证方式见 [distro-packages.md](distro-packages.md)。

## 当前限制

- Office→PDF 缺 Linux 原生 LibreOfficeKit，明确跳过；
- Flatpak 尚未提交 Flathub，且 24.08 runtime 已 EOL；
- Snap / Arch / openSUSE OBS 尚未实现；
- Wayland/托盘/输入法未验收。
