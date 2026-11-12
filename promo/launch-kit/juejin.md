# 掘金文章

标题：

```text
把官方 DeepSeek Harness 桌面端打包进 Linux 发行版：AppImage、deb、rpm 与 Flatpak 的工程实践
```

结构：

1. 问题：官方桌面没有 Linux 发行包
2. 定位：下游打包，不改 agent 内核
3. 为什么不是“再写一个 AI 客户端”
4. 四种格式的取舍：AppImage / deb / rpm / Flatpak
5. APT/DNF 静态仓库与 CI 安装冒烟
6. 签名链：GPG、SHA256SUMS、SBOM、provenance
7. Linux 桌面坑：FUSE、chrome-sandbox、Wayland、依赖命名
8. 已知限制与下一步
9. 下载与反馈入口

结尾 CTA：

```text
项目地址：https://github.com/openviewmobile/dshd-linux
当前 RC：https://github.com/openviewmobile/dshd-linux/releases/tag/v0.2.2-rc.1.3
```

不要写“全发行版已验证”；只写 CI 验证过的内容和仍待真机验证的内容。
