# Linux 项目文档

| 文档 | 内容 |
|---|---|
| [architecture.md](architecture.md) | 上游 desktop 分叉、Linux target、运行时与打包链路 |
| [testing.md](testing.md) | Docker/Xvfb 冒烟、格式验证、证据 |
| [release.md](release.md) | AppImage/deb/rpm/Flatpak、签名、更新与限制 |
| [distro-packages.md](distro-packages.md) | 发行版/包格式矩阵、分层建议、技术约束与 CI 验证 |
| [research/official-desktop-audit.md](research/official-desktop-audit.md) | 官方桌面端审计与 Linux 发布缺口 |
| [adr/](adr/) | 相关 ADR（Electron、分叉上游、开源分发、全本地范围） |

发行版支持分三层：Tier 1 为已产出的 AppImage/deb/rpm/Flatpak；Tier 2 为计划中的
Snap、Arch/AUR、openSUSE OBS；Tier 3 为 Gentoo、Nix（机会性），Alpine 因 musl 与
Electron 官方 glibc 二进制不兼容而**明确不支持**。详见
[distro-packages.md](distro-packages.md)。

项目入口与命令见 [../README.md](../README.md)。
