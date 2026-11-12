# 知乎回答/文章

适合的问题：

- Linux 上有什么好用的 DeepSeek 桌面客户端？
- DeepSeek Harness 桌面端有 Linux 版吗？
- 如何把 Electron 应用打包成 AppImage/deb/rpm/Flatpak？

回答框架：

1. 先直接回答：官方目前没有 Linux 发行包
2. 说明这个项目补的是“发行版级打包”，不是模型/客户端重写
3. 列安装方式（AppImage / apt / dnf / Flatpak）
4. 强调验证链（GPG、SBOM、provenance）
5. 明确限制（RC、Wayland 真机、自动更新验收、Flathub/AUR）
6. 给出 Release 链接和反馈方式

一段可直接用的开头：

```text
官方 DeepSeek Harness 桌面端目前只提供 macOS/Windows 构建。Linux 用户能用 Web 版或源码运行，但缺少发行版级安装包。这个项目把官方 Electron 桌面打包成 AppImage、deb、rpm 和 Flatpak，并提供 APT/DNF 仓库和签名 Release；它不修改 agent 内核，也不是官方项目。
```
