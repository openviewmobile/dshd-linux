# ADR-0003：分叉上游仓库，而不是从零重写桌面壳

> 说明：本 ADR 来自跨端仓库；未随本项目迁移的文档引用以纯文本保留。

- 状态：提议（Proposed）
- 日期：2026-11-08
- 决策者：架构组
- 相关：[ADR-0001](0001-electron-desktop.md)、[目标架构](../architecture.md)

## 背景

上游 `deepseek-ai/deepseek-harness` 是 MIT 许可的 monorepo，包含：

- `apps/desktop`：Electron 壳，macOS/Windows 生产化；
- `apps/desktop-host`：Electron RunAsNode 的私有 Host；
- `apps/cli`：dsh CLI；
- `packages/*`：300+ 包（Agent、工具、Web UI、插件）；
- 打包脚本：运行时准备、Python/pnpm、签名、公证、更新、恢复。

从零写一个 Electron 壳只需几百行，但要达到“消费级可发布”需要重做上述所有平台工作。

## 决策

1. 以 **fork + 上游 remote** 的方式维护代码：
   - `upstream` 指向 `deepseek-ai/deepseek-harness`；
   - 固定 tag（如 `dsh-v0.2.2-rc.1`）；
   - 产品化改动尽量放在 `products/dshd` 或 `patches/`。
2. 不把上游代码复制成“无历史的新仓库”；保留 git 历史以便 rebase。
3. 每个上游版本升级跑桌面冒烟与签名验证。
4. 如果上游 license/维护策略变化，保留“最小自研壳”作为退出路径。

## 理由

- **时间**：复用生产化壳，桌面 MVP 2–3 个月；从零 6–10 个月。
- **质量**：上游已处理签名、公证、更新、恢复、单实例、登录 shell、运行时校验。
- **成本**：少维护 70+ 平台文件与 CI 脚本。
- **风险**：MIT 允许分叉；但品牌/官方服务需替换。

## 后果

### 正面

- 快速交付；平台细节有上游背书。
- 上游安全/兼容修复可通过 rebase 获得。
- 团队聚焦品牌、引导、移动端、分发。

### 负面

- 需要维护补丁集；上游重构会造成冲突。
- 上游 monorepo 大（pnpm workspace、数百包），构建慢。
- 上游可能耦合官方账号/遥测/更新策略，需要剥离。
- 品牌与官方服务不在 MIT 范围内。

### 缓解

- 补丁最小化；产品代码独立 package；CI 检查补丁可应用。
- 固定上游版本，按季度升级；不追 master。
- 建立“上游变更看板”：安全、API、桌面、Web。
- 法务审查品牌/第三方许可证（Electron、Python、LibreOffice、字体）。

## 备选方案

| 方案 | 优点 | 缺点 |
|---|---|---|
| 从零写 Electron 壳 | 代码可控、包体可裁剪 | 6–10 个月；平台坑多；更新/签名/恢复要重做 |
| 直接使用官方 Desktop + 插件 | 最快 | 无法品牌化/定制首启/移动端；依赖官方服务 |
| 只做 Web + PWA | 最简单 | 没有本地文件/终端；不符合桌面 App 需求 |
| Tauri 重写 | 包体小 | 需要 Node sidecar；上游资产不可复用 |

## 验证方式

- M0：克隆上游、构建 macOS desktop、打未签名 DMG。
- 打一个品牌补丁（应用名/图标/关于页），确认补丁集可维护。
- 升级到下一个 rc，测量 rebase 冲突与冒烟时间。

## 复审条件

- 上游 desktop 不再维护/许可变更；
- 补丁冲突成本超过自研成本；
- 产品需要大规模裁剪（如去掉 Python/Office/插件），分叉反而累赘；
- 品牌/法务要求完全独立代码库。
