# Linux 测试

## Docker + Xvfb

```bash
# 项目根目录
docker build -f Dockerfile -t dshd-linux-test .
docker volume create dshd-linux-src
docker run --rm -it \
  -v "$PWD:/work" \
  -v dshd-linux-src:/src \
  dshd-linux-test
# 容器内
/work/scripts/build-and-smoke.sh
```

脚本会克隆上游、应用补丁、`pnpm install`、构建 `linux-<arch>:dir`，在 Xvfb 1440×900
中启动 App，检查进程存活并截图。

> `/src` 必须使用 Docker named volume；macOS bind mount 会在 electron-builder 复制
> Windows `node.cmd` 时触发 `EACCES: permission denied, chmod`。

## 格式验证

```bash
# 在项目根目录
scripts/verify-artifacts.sh

# deb GUI 冒烟（x64）
scripts/smoke-deb-x64.sh

# Flatpak GUI 冒烟（x64，Docker 需要能创建 namespace）
scripts/smoke-flatpak-x64.sh
```

已验证：

- arm64 deb/rpm/Flatpak 结构检查；
- deb 在 amd64 Docker + Xvfb 中安装并启动，窗口与本地 Host 正常；
- Flatpak bundle 安装验证通过，GUI 需真机（Docker seccomp 限制 bwrap）；
- AppImage 在 arm64/ x64 的 Xvfb 中启动；
- x64 `verify-artifacts.sh` 对现有 AppImage/deb/rpm/Flatpak 全部 `OK`。

## 证据

- `../evidence/linux-ui-*.png`：欢迎页、Provider、插件安装/启用/卸载、设置；
- `../evidence/x64-*.txt`、`../evidence/deb-x64-smoke.png`；
- `../evidence/flatpak-*.txt`、`../evidence/SHA256SUMS.*`。

## 未覆盖

- 真实 Linux 桌面（非容器）的长期运行；
- Wayland/输入法/托盘；
- 自动更新；
- Office→PDF。
