# Linux 发布

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
- `targetSdk`/系统依赖按 Electron 与 Flatpak runtime 24.08 要求执行。

## 当前限制

- Office→PDF 缺 Linux 原生 LibreOfficeKit，明确跳过；
- Flatpak 尚未提交 Flathub；
- Wayland/托盘/输入法未验收。
