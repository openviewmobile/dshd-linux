# ADR-0001：桌面端采用 Electron，并分叉上游 `apps/desktop`

> 说明：本 ADR 来自跨端仓库；未随本项目迁移的文档引用以纯文本保留。

- 状态：提议（Proposed）
- 日期：2026-11-08
- 决策者：架构组
- 相关：跨端方案研究、[目标架构](../architecture.md)

## 背景

dsh 要求 Node.js >= 24.9.0，工具面依赖本地 shell、文件系统、pnpm、Python、原生模块。桌面端需要：

- 安装即用，不要求用户装 Node/pnpm；
- 能执行本地命令、读写工作区、跑长任务；
- 自动更新、签名、公证、崩溃恢复；
- 复用 dsh Web UI。

候选：Electron、Tauri 2、Wails 3、Qt WebEngine。上游已经有一个生产化的 Electron 桌面壳（`apps/desktop`），包含运行时准备、更新、恢复、签名等 70+ 文件。

## 决策

1. 桌面端采用 **Electron 44**（Node 24.21 / Chromium 152）。
2. **分叉上游 `deepseek-ai/deepseek-harness`**，以 `apps/desktop` 为基线，而不是从零写壳。
3. 保持上游的“Electron 壳 + `ELECTRON_RUN_AS_NODE` Host 子进程 + 打包 Web 入口”架构。
4. 产品化改动放在独立目录/补丁集，尽量不修改上游文件。

## 理由

- **Node 兼容**：Electron 自带 Node 24，满足 dsh `engines`；Tauri 需要额外 Node sidecar。
- **复用资产**：更新、签名、公证、恢复、单实例、登录 shell 环境、目录选择、托盘等都已实现。
- **UI 一致性**：Chromium 固定版本，不受 Linux WebKitGTK / Windows WebView2 版本碎片影响。
- **风险可控**：上游已在 macOS/Windows 生产验证；我们补 Linux 与品牌/引导即可。
- **生态**：Electron 的签名、更新、崩溃、DevTools 工具链成熟。

## 后果

### 正面

- 首版时间从 6–10 个月降到 2–3 个月（桌面 MVP）。
- 原生模块/运行时问题有上游先例。
- 未来上游升级可通过 rebase 补丁跟进。

### 负面

- 包体大（Electron + dsh deps + Python，估算 300–500 MB）。
- 内存占用高（Chromium + Node Host）。
- 需要维护上游补丁集，升级有冲突成本。
- Electron 安全公告需要跟进（Chromium/Node 升级）。

### 缓解

- Python/Office 运行时按需下载，首发可精简。
- 差分更新减少下载量。
- 建立上游同步 CI：每周 rebase，跑冒烟。
- 安全响应：订阅 Electron 安全公告，30 天内升级。

## 备选方案

| 方案 | 为什么不选 |
|---|---|
| Tauri 2 | 需要 Node sidecar；要重写壳与更新/恢复；WebView 差异；上游资产无法复用 |
| Wails 3 | 生态小；无 Node；需要重写 |
| Qt WebEngine | 许可/集成/包体成本高；团队不熟 |
| 纯 WebView2/WebKit | 平台差异大；无统一更新/签名方案 |

## 验证方式

- M0 原型：Electron 44 + dsh，macOS arm64，启动 Host、加载 UI、完成 token 交换；工具调用与打包运行时待验证。
- 包体/启动/内存基线；与 Tauri PoC 对比（可选）。
- 上游 desktop 构建成功；能打出未签名 DMG。

## 复审条件

- Electron 包体/内存成为不可接受的产品问题；
- 上游 desktop 停止维护或 license 变更；
- Tauri 生态出现成熟的 Node 24 sidecar + 认证/更新方案；
- 企业客户要求更小安装包/更严格沙箱。
