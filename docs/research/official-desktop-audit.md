# 官方桌面端完备性审计（macOS / Windows / Linux）

> 说明：本文来自跨端仓库；未随本项目迁移的文档引用以纯文本保留。

- 审计对象：`deepseek-ai/deepseek-harness`，commit `fcc0ad4`（2026-11-04），`@deepseek-ai/dsh-desktop@0.2.2-rc.1`。
- 目的：判断 macOS / Windows / Linux 三端是否还需要我们做桌面客户端。
- 结论：**macOS、Windows 已经非常完备；Linux 明确不是官方支持的 Desktop 发布目标；三端都仍有产品层缺口（自定义 provider 首启、本地-only/无埋点、自有签名/更新/品牌）。**

---

## 1. 总体结论

| 平台 | 官方桌面完备度 | 判断 |
|---|---|---|
| macOS arm64/x64 | **高（约 90%）** | 不需要重写；最多做薄产品层 |
| Windows x64 | **高（约 90%）** | 不需要重写；最多做薄产品层 |
| Linux | **低（不是发布目标）** | 官方不发布；要做就得自己补打包/更新/签名 |
| Android | **无** | 官方没有；这是真正的空白 |

“官方有 Electron 代码”不是全部；关键是**发布链路是否支持**。  
macOS/Windows 有完整安装包、签名、公证、更新；Linux 没有。

---

## 2. 官方已经做了什么

### 2.1 运行时

- Electron 44 + `ELECTRON_RUN_AS_NODE`；
- 内置 Node.js、pnpm、Python（含 numpy/pandas/python-docx/python-pptx/openpyxl/Pillow/lxml/XlsxWriter）；
- 内置完整 dsh 生产依赖；
- 不需要系统 Node/Python/pnpm；
- 插件使用内置 pnpm 安装。

### 2.2 桌面壳

- 主窗口、托盘、关闭到托盘、单实例；
- macOS/Windows/Linux 菜单与快捷键；
- 深链 `dsh://open`；
- 文件拖放、原生目录选择、文件图标；
- 内置浏览器 guest、账号页面；
- CLI 注册/修复/移除（`dsh` 命令）；
- 设备信息、麦克风权限、崩溃恢复、诊断报告；
- 8 种界面语言。

### 2.3 打包与发布

| 能力 | macOS | Windows | Linux |
|---|---|---|---|
| 安装包 | DMG/ZIP | NSIS EXE | **无官方目标** |
| 签名 | Apple Developer ID | Authenticode/EV | 无 |
| 公证 | ✅ | — | — |
| 自动更新 | electron-updater | electron-updater | 无官方 |
| 强制更新/更新遮罩 | ✅ | ✅ | — |
| 发布上传 | COS/CDN | COS/CDN | — |
| 构建主机 | macOS | Windows x64 | — |

官方 `package-target.ts` 的 `TARGETS` 只有：

- `mac-arm64`
- `mac-x64`
- `win-x64`

官方文档明确写：

> Linux 不是受支持的 Desktop 发布目标。

这不是“没测试”，而是**打包/签名/更新/发布链路都没有把 Linux 作为目标**。

### 2.4 首启

- Welcome 窗口；
- 官方账号登录（代码存在，但当前“已知限制”写账号登录尚未接入、按钮禁用）；
- 官方 provider API Key 保存；
- “稍后配置”进入工作区；
- 语言选择；
- API Key 空输入、禁用自动填充。

### 2.5 恢复/诊断

- 致命启动失败恢复对话框；
- 退出/重启/禁用第三方插件并备份 patch/获取诊断；
- 更新失败恢复；
- 运行中任务退出确认；
- 定时任务提醒。

### 2.6 插件

- 完整 Web 插件管理器；
- Desktop profile 独立；
- 第三方 bundle 安装/激活/修复；
- 插件市场 UI。

---

## 3. 关键缺口

### 3.1 Linux：不是官方发布目标

官方代码里有 Linux 行为适配（菜单、目录选择、快捷键、登录 shell 环境），但：

- 没有 `linux-*` 打包目标；
- 没有 Linux 签名/更新/发布脚本；
- 文档明确“不支持”。

如果 v1 要 Linux，需要自己补：

- electron-builder Linux target（AppImage/deb）；
- 更新源与签名；
- 托盘/桌面文件/沙箱测试；
- CI runner；
- 发行说明/支持矩阵。

这是**真实工作量**，不是改一行配置。

### 3.2 首启只面向官方 provider

`welcome-api.ts` 的注释是：

> Store the official provider's key before entering the workspace.

`welcome-backend.ts` 只找官方 provider 的 `apiKeyEnv`。  
也就是说：

- 官方桌面首启 = 官方 DeepSeek API Key / 官方账号；
- **没有“自定义 baseURL + token + provider 预设”的消费级向导**；
- 自定义 provider 需要进入工作区后在设置里配置。

如果你的产品承诺“普通用户只填 provider/baseURL/token 就能用”，这是一个明确缺口。

### 3.3 本地-only / 无埋点

官方桌面有产品埋点框架：

- `product-analytics`；
- Welcome 页 `auth_page_view`、`api_key_save_click`；
- 是否启用由产品采集策略动态决定。

如果产品定位是“完全本地、无遥测”，需要：

- 关闭/移除 analytics；
- 确认 Host/Client 侧没有默认上报；
- 自托管更新/账号策略。

### 3.4 品牌、签名、更新域名

官方桌面是 DeepSeek 品牌：

- 应用名、图标、关于面板；
- 官方账号/平台页面；
- `download.deepseek.com` 更新源；
- 官方签名/公证身份。

你不能直接用官方签名发布自己的安装包。  
要么：

- 基于 MIT 源码 fork，使用自己的品牌/证书/更新源；
- 或者直接让用户用官方桌面，你不发布桌面版。

### 3.5 平台/架构矩阵

官方只发布：

- macOS arm64；
- macOS x64；
- Windows x64。

没有：

- Windows arm64；
- Linux x64/arm64。

如果你的用户有 Windows ARM 或 Linux，官方覆盖不了。

### 3.6 账号登录尚未完成

官方“已知限制”写：

> 账号登录尚未接入；登录按钮禁用。

这意味着官方桌面当前更偏“API Key + 工作区”，不是完整消费级账号产品。  
对普通用户首启体验仍有提升空间。

---

## 4. 对我们的意义

### 如果目标用户 = 官方 DeepSeek API 用户，且只用 macOS/Windows

**官方桌面已经够用。**  
我们不需要做桌面客户端；最多做：

- 中文文档/支持；
- 首启说明；
- 企业分发/配置；
- 或者直接推荐官方安装包。

### 如果目标用户 = 非技术用户 + 自定义 provider/baseURL/token

官方首启不够。  
我们需要薄产品层：

1. 自定义 provider 向导；
2. baseURL/token 校验；
3. 预设 provider；
4. 中文错误恢复；
5. 本地-only 默认；
6. 自有签名/更新。

但仍**不要重写 Electron 壳**。

### 如果必须支持 Linux

官方没有发布目标。  
我们要自己补 Linux 打包/更新/签名；这是独立工作流，不是“顺手加一个 target”。

### Android

官方完全没有。  
这是唯一真正的平台空白，也是产品最该投入的地方。

---

## 5. 建议

1. **macOS/Windows：复用官方 desktop，做薄产品层；不重写。**
2. **Linux：先确认是否是 v1 必须；如果是，单独列 4–8 周 Linux 发布工作流。**
3. **Android：自研本地 runtime；这是核心差异化。**
4. **桌面是否发布独立品牌：取决于你是否需要自定义 provider/本地-only/自有更新；如果不需要，直接指向官方桌面。**
5. **不要因为“官方有桌面”就完全放弃桌面产品化；也不要因为“官方有代码”就重写一遍。**

---

## 6. 证据索引

- [官方 Desktop README（中文）](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/README.zh.md)
- [官方 Desktop 打包文档](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/packaging/README.zh.md)
- [官方 Desktop 发布文档](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/publishing/README.zh.md)
- [package-target.ts](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/scripts/package-target.ts)
- [welcome-api.ts](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/src/welcome-api.ts)
- [welcome-backend.ts](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/src/welcome-backend.ts)
- [electron-builder 配置](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/electron-builder.config.mjs)
