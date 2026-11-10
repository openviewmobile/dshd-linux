# ADR-0005：GitHub 开源 + 预编译安装包分发

> 说明：本 ADR 来自跨端仓库；未随本项目迁移的文档引用以纯文本保留。

- 状态：提议（Proposed）；分发渠道部分被 ADR-0006 修订/评估中

- 日期：2026-11-08
- 决策者：产品/架构
- 相关：[ADR-0001](0001-electron-desktop.md)、ADR-0002、[ADR-0003](0003-fork-upstream.md)、发布矩阵、设备本地运行研究

> 注：若 ADR-0006 采纳，iOS 改为 IPA sideload、Android 改为仅 APK 分发；本文中“iOS App Store/TestFlight、Android Play”的渠道描述不再适用，其余签名/供应链/许可原则仍适用。

## 背景

项目计划：

- 在 GitHub 开源；
- 提供编译好的安装程序，普通用户下载后即可使用；
- 桌面本地跑 dsh 内核；
- Android 探索设备本地内核；
- iOS/Android 也可能有远程伴生模式。

这与“只发源码、让用户自己构建”不同：需要同时处理**许可证、签名、公证、更新、供应链、商店规则和普通用户安装体验**。

## 决策

### 1. 代码许可

1. **自有代码默认建议 Apache-2.0**（待法务/产品最终确认）：
   - 专利授权、商誉条款、与 MIT 上游兼容；
   - 便于公司/企业采用，也便于社区贡献。
2. 保留 dsh 上游的 **MIT** 版权与许可声明；分叉的 `apps/desktop` 代码同样保留 MIT。
3. 不以 GPL 作为默认许可；GPL 运行时（PRoot、Termux 等）**隔离为独立 runtime pack**，按 GPL 履行源码义务，具体由法务确认。
4. **不使用 DeepSeek 名称/图形/官方服务标识**作为产品品牌；README 中注明“非官方、基于 dsh”，并保留上游商标声明。

> 备选：若项目希望强制回馈社区，可选 GPLv3；但 GPLv3 与 iOS App Store 的附加限制存在冲突风险，且会降低企业采用意愿。若 Android 本地运行时必须用 PRoot/Termux，GPLv3 是最省事的合规路径，但应把 iOS 远程客户端与 GPL 运行时隔离。

### 2. 分发渠道

| 平台 | 主渠道 | 安装包 | 备注 |
|---|---|---|---|
| macOS | GitHub Releases + 官网下载页 | 签名/公证的 DMG、ZIP | Gatekeeper 必须通过 |
| Windows | GitHub Releases + 官网下载页 | Authenticode 签名的 NSIS `.exe` | SmartScreen 信誉 |
| Linux | GitHub Releases + 官网下载页 | AppImage、deb、校验和/GPG | 无系统强制签名 |
| Android 本地版 | **GitHub Releases APK** | targetSdk 28、本地 runtime | 不能上 Play |
| Android 远程版 | Google Play（可选）+ GitHub APK | target 最新、伴生客户端 | 与本地版分 SKU |
| iOS | **App Store / TestFlight** | `.ipa` 仅商店/测试 | GitHub 不能给普通用户安装 |
| Web | 自托管 Docker / GitHub Pages 静态壳 | 容器镜像/静态文件 | 内核在服务器 |

**关键结论**：GitHub Releases 适合桌面和 Android APK，**不适合 iOS 消费级分发**。iOS 仍然只能走 App Store/TestFlight；开源不会改变这一点。

### 3. 签名与公证不可省

- **macOS**：Developer ID Application 证书 + Hardened Runtime + notarytool 公证 + staple；未公证的 DMG 会被 Gatekeeper 拦截。开源不豁免。
- **Windows**：Authenticode（OV/EV）签名安装器和所有 EXE/DLL；否则 SmartScreen 警告会显著降低普通用户转化。时间戳必须。
- **Android**：APK 签名密钥离线/HSM 保管；本地版与远程版使用不同 applicationId/签名策略；`targetSdk 28` 仅用于本地版。
- **Linux**：SHA-256 校验和 + GPG 签名；AppImage 内置更新需校验签名。
- **iOS**：Apple Distribution 证书 + App Store Review；GitHub 只放源码和校验信息。

### 4. 更新与供应链

1. 桌面更新走 **签名 feed**（electron-updater / Sparkle），不直接信任 GitHub `latest` JSON；更新包必须验签。
2. Android 本地版提供应用内“检查更新 → 下载 APK → 校验 SHA-256/签名 → 调起安装器”；需要 `REQUEST_INSTALL_PACKAGES`，并明确提示未知来源。
3. GitHub Actions 使用**受保护 environment**、OIDC、最小权限 `GITHUB_TOKEN`；发布 job 不能由 PR 触发。
4. 每个 release 附带：
   - `SHA256SUMS`；
   - `SHA256SUMS.sig`（GPG/Sigstore）；
   - `sbom.spdx.json`；
   - `provenance.intoto.jsonl`（SLSA）；
   - 构建 commit、工具链版本、运行时清单。
5. 签名密钥离线/HSM；CI 只拿短期凭据；密钥轮换与吊销流程写入 `SECURITY.md`。
6. 防冒充：官方域名、固定签名指纹、Release 校验说明；不通过第三方网盘分发未校验二进制。

### 5. Android 本地版是独立 SKU

- 本地版：`targetSdk 28`，Cortex-style glibc 或 PRoot runtime；**只通过 GitHub APK / 企业 MDM 分发**，不上 Play。
- 远程版：`targetSdk` 最新，Capacitor/Flutter 伴生客户端；可上 Play。
- 两者可以共享 UI/业务代码，但**构建变体、签名、商店条目、隐私声明分开**。
- 不要试图用一个 APK 同时满足“本地内核 + Play 上架”；targetSdk/exec 规则冲突。

### 6. iOS 不做本地内核

- 开源不改变 iOS 的 `fork/exec`、JIT、后台和 App Store 2.5.2 限制。
- iOS 只做远程伴生客户端；iSH/UTM SE 仅作为外部演示，不进入产品承诺。
- 如果未来 App Store 规则或 EU DMA 出现可用的本地运行时通道，再单独立项评估。

## 理由

- **信任**：开源 + 可复现构建 + 签名/校验，能降低“闭源壳拿我 API Key”的顾虑。
- **成本**：GitHub Releases 零分发成本；官网只做下载页/文档，不承担 CDN 之外的分发系统。
- **速度**：桌面/Android 可直接发二进制，不必等商店审核；iOS 仍受商店约束。
- **合规**：开源使 GPL 运行时的源码义务更容易满足，但不能消除 targetSdk/App Store 的平台限制。
- **生态**：社区可提交 provider、工具适配、文档；但核心运行时和签名密钥必须受控。

## 后果

### 正面

- 桌面和 Android 可以快速迭代、灰度、回滚。
- 用户/企业可审计代码、自己构建。
- GitHub Issues/Discussions 形成支持与插件生态。
- 开源项目更容易获得代码签名、CI、安全扫描的社区资源。

### 负面

- **支持负担**：普通用户会把“安装失败/模型连不上/被杀软拦截”提到 Issues；需要模板、FAQ、诊断工具。
- **安全暴露**：本地 Agent + shell + API Key，攻击面大；需要威胁模型、审批、密钥管理、漏洞响应。
- **签名成本**：Apple Developer $99/年；Windows OV/EV 证书与 HSM；Android 密钥管理；CI macOS runner 成本。
- **许可复杂**：dsh MIT、Electron/Chromium、Cortex Apache、PRoot/Termux GPL、Ubuntu/Debian rootfs 各自义务。
- **品牌风险**：必须与 DeepSeek 官方明确切割，避免商标/背书误解。
- **中国下载体验**：GitHub 访问不稳定；需要镜像/对象存储，且镜像必须与官方校验和一致。

### 缓解

- 官网做 OS 检测下载页，GitHub Releases 作为后端；普通用户不直接面对 Release 页面。
- 安装包内置诊断/日志导出；首启向导自动检测 Gatekeeper/SmartScreen/未知来源。
- `SECURITY.md`、`CONTRIBUTING.md`、`CODE_OF_CONDUCT.md`、Issue 模板、漏洞私密报告。
- 分支保护、CODEOWNERS、Dependabot、CodeQL、secret scanning、2FA。
- 发布密钥与构建密钥分离；release 采用双人复核。
- 对 GPL runtime 单独仓库/单独压缩包，附对应源码与构建脚本。

## 备选方案

| 方案 | 优点 | 缺点 |
|---|---|---|
| 只发源码，用户自行构建 | 合规最简单、成本最低 | 违背“开箱即用”，普通用户不可用 |
| GitHub Releases 全平台 | 统一、便宜 | iOS 不可安装；Android 本地版被 Play 规则限制 |
| 只发商店 | 信任/安装体验好 | 审核慢；本地内核无法上 Play/App Store |
| 闭源 + 免费二进制 | 保护实现 | 用户不信任本地 Agent；社区贡献弱 |
| 开源 + 商业托管 | 可持续 | 需要账号/计费/合规；与“本地优先”定位冲突 |

## 验证方式

- M0：用 GitHub Actions 构建一个未签名 macOS DMG + Windows NSIS + Linux AppImage，验证产物和校验和。
- M1：完成 macOS 签名/公证，GitHub Release 下载安装通过 Gatekeeper。
- M2：Windows Authenticode + SmartScreen 观察；Android APK 签名与升级。
- M3：生成 SBOM、Sigstore/GPG 校验、release provenance。
- M4：iOS TestFlight；确认 GitHub 不作为 iOS 安装渠道。
- M5：Android 本地版独立 APK（targetSdk 28）与远程版分离验证。

## 复审条件

- 许可证最终选择变化（Apache-2.0 ↔ GPLv3）；
- Apple/Google 商店规则变化（尤其 EU DMA、iOS 本地运行时）；
- Android targetSdk/exec 规则出现可用例外；
- 签名/公证成本或失败率不可接受；
- 社区支持负担超过团队承受能力；
- 品牌/商标方提出异议。
