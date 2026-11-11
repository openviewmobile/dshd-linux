# Official Desktop Completeness Audit (macOS / Windows / Linux)

> Note: this document comes from a cross-platform repository; document references that were not migrated with this project are kept as plain text.

- Audit target: `deepseek-ai/deepseek-harness`, commit `fcc0ad4` (2026-11-04), `@deepseek-ai/dsh-desktop@0.2.2-rc.1`.
- Purpose: determine whether macOS / Windows / Linux still need us to build a desktop client.
- Conclusion: **macOS and Windows are already very complete; Linux is clearly not an officially supported Desktop release target; all three platforms still have product-layer gaps (custom provider on first launch, local-only/no telemetry, our own signing/updates/branding).**

---

## 1. Overall Conclusion

| Platform | Official desktop completeness | Judgment |
|---|---|---|
| macOS arm64/x64 | **High (about 90%)** | No rewrite needed; at most a thin product layer |
| Windows x64 | **High (about 90%)** | No rewrite needed; at most a thin product layer |
| Linux | **Low (not a release target)** | Not published officially; doing it means supplying our own packaging/updates/signing |
| Android | **None** | Not offered officially; this is the real gap |

"Officially has Electron code" is not the whole story; what matters is **whether the release pipeline supports it**.
macOS/Windows have complete installers, signing, notarization, and updates; Linux has none.

---

## 2. What the Official Desktop Already Does

### 2.1 Runtime

- Electron 44 + `ELECTRON_RUN_AS_NODE`;
- Bundled Node.js, pnpm, Python (including numpy/pandas/python-docx/python-pptx/openpyxl/Pillow/lxml/XlsxWriter);
- Bundled full dsh production dependencies;
- No system Node/Python/pnpm required;
- Plugins are installed using the bundled pnpm.

### 2.2 Desktop Shell

- Main window, tray, close-to-tray, single instance;
- macOS/Windows/Linux menus and shortcuts;
- Deep link `dsh://open`;
- File drag-and-drop, native directory selection, file icons;
- Built-in browser guest, account pages;
- CLI registration/repair/removal (the `dsh` command);
- Device information, microphone permission, crash recovery, diagnostic reports;
- 8 UI languages.

### 2.3 Packaging and Publishing

| Capability | macOS | Windows | Linux |
|---|---|---|---|
| Installer | DMG/ZIP | NSIS EXE | **No official target** |
| Signing | Apple Developer ID | Authenticode/EV | None |
| Notarization | ✅ | — | — |
| Auto update | electron-updater | electron-updater | No official support |
| Forced update/update overlay | ✅ | ✅ | — |
| Release upload | COS/CDN | COS/CDN | — |
| Build host | macOS | Windows x64 | — |

The official `package-target.ts` `TARGETS` contains only:

- `mac-arm64`
- `mac-x64`
- `win-x64`

The official documentation states explicitly:

> Linux is not a supported Desktop release target.

This is not "untested"; it means **the packaging/signing/update/publishing chain nowhere targets Linux**.

### 2.4 First Launch

- Welcome window;
- Official account sign-in (the code exists, but the current "known limitations" say account sign-in is not yet wired up and the button is disabled);
- Official provider API Key storage;
- "Configure later" enters the workspace;
- Language selection;
- Empty API Key input, autofill disabled.

### 2.5 Recovery/Diagnostics

- Fatal startup failure recovery dialog;
- Quit/restart/disable third-party plugins with patch backup/get diagnostics;
- Update failure recovery;
- Confirmation when quitting with running tasks;
- Scheduled task reminders.

### 2.6 Plugins

- Complete Web plugin manager;
- Separate Desktop profile;
- Third-party bundle install/activation/repair;
- Plugin marketplace UI.

---

## 3. Key Gaps

### 3.1 Linux: Not an Official Release Target

The official code contains Linux behavior adaptations (menus, directory selection, shortcuts, login shell environment), but:

- There is no `linux-*` packaging target;
- There are no Linux signing/update/publishing scripts;
- The documentation explicitly says "not supported".

If v1 needs Linux, we must supply:

- electron-builder Linux targets (AppImage/deb);
- Update source and signing;
- Tray/desktop files/sandbox testing;
- CI runners;
- Release notes/support matrix.

This is **real work**, not a one-line config change.

### 3.2 First Launch Is Only for the Official Provider

The comment in `welcome-api.ts` reads:

> Store the official provider's key before entering the workspace.

`welcome-backend.ts` only looks for the official provider's `apiKeyEnv`.
In other words:

- Official desktop first launch = official DeepSeek API Key / official account;
- **There is no consumer-grade wizard for "custom baseURL + token + provider preset"**;
- A custom provider must be configured in settings after entering the workspace.

If your product promises "ordinary users just fill in provider/baseURL/token and it works", this is a clear gap.

### 3.3 Local-only / No Telemetry

The official desktop has a product analytics framework:

- `product-analytics`;
- `auth_page_view`, `api_key_save_click` on the Welcome page;
- Whether it is enabled is decided dynamically by the product collection policy.

If the product positioning is "fully local, no telemetry", you need to:

- Disable/remove analytics;
- Confirm that neither Host nor Client reports by default;
- Self-host updates/account policy.

### 3.4 Branding, Signing, Update Domain

The official desktop carries DeepSeek branding:

- App name, icon, About panel;
- Official account/platform pages;
- `download.deepseek.com` update source;
- Official signing/notarization identity.

You cannot publish your own installer using the official signature.
Either:

- Fork the MIT source and use your own branding/certificate/update source;
- Or just let users use the official desktop and do not ship a desktop build yourself.

### 3.5 Platform/Architecture Matrix

The official releases are only:

- macOS arm64;
- macOS x64;
- Windows x64.

Nothing for:

- Windows arm64;
- Linux x64/arm64.

If your users have Windows ARM or Linux, the official build does not cover them.

### 3.6 Account Sign-in Is Not Finished

The official "known limitations" say:

> Account sign-in is not yet wired up; the sign-in button is disabled.

This means the official desktop currently leans toward "API Key + workspace" rather than a complete consumer account product.
There is still room to improve the first-launch experience for ordinary users.

---

## 4. What This Means for Us

### If the Target Users = Official DeepSeek API Users, and They Only Use macOS/Windows

**The official desktop is already sufficient.**
We do not need to build a desktop client; at most we do:

- Chinese documentation/support;
- First-launch guidance;
- Enterprise distribution/configuration;
- Or simply recommend the official installer.

### If the Target Users = Non-technical Users + Custom provider/baseURL/token

The official first launch is not enough.
We need a thin product layer:

1. Custom provider wizard;
2. baseURL/token validation;
3. Preset providers;
4. Chinese error recovery;
5. Local-only by default;
6. Our own signing/updates.

But still **do not rewrite the Electron shell**.

### If Linux Must Be Supported

The official build has no release target.
We must supply Linux packaging/updates/signing ourselves; that is a separate workflow, not "just add another target".

### Android

The official offering has nothing at all.
This is the only real platform gap, and where the product most deserves investment.

---

## 5. Recommendations

1. **macOS/Windows: reuse the official desktop and build a thin product layer; do not rewrite.**
2. **Linux: first confirm whether it is mandatory for v1; if it is, plan a separate 4–8 week Linux release workflow.**
3. **Android: build our own local runtime; this is the core differentiator.**
4. **Whether to ship the desktop under a separate brand: depends on whether you need a custom provider/local-only/your own updates; if not, point users straight at the official desktop.**
5. **Do not abandon desktop productization just because "the official build exists"; and do not rewrite it just because "the official code exists".**

---

## 6. Evidence Index

- [Official Desktop README (Chinese)](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/README.zh.md)
- [Official Desktop packaging docs](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/packaging/README.zh.md)
- [Official Desktop publishing docs](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/publishing/README.zh.md)
- [package-target.ts](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/scripts/package-target.ts)
- [welcome-api.ts](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/src/welcome-api.ts)
- [welcome-backend.ts](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/src/welcome-backend.ts)
- [electron-builder config](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/desktop/electron-builder.config.mjs)
