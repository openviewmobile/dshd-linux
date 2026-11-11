# ADR-0001: Use Electron for the Desktop App and Fork Upstream `apps/desktop`

> Note: This ADR comes from the cross-platform repository; references to documents that were not migrated with this project are retained as plain text.

- Status: Proposed
- Date: 2026-11-08
- Deciders: Architecture Group
- Related: cross-platform solution research, [Target Architecture](../architecture.md)

## Context

dsh requires Node.js >= 24.9.0, and its tool surface depends on a local shell, filesystem, pnpm, Python, and native modules. The desktop app needs to:

- Work out of the box, without requiring users to install Node/pnpm;
- Be able to execute local commands, read and write the workspace, and run long tasks;
- Auto-update, signing, notarization, crash recovery;
- Reuse the dsh Web UI.

Candidates: Electron, Tauri 2, Wails 3, Qt WebEngine. Upstream already has a production-grade Electron desktop shell (`apps/desktop`) containing 70+ files for runtime preparation, updates, recovery, signing, and more.

## Decision

1. The desktop app uses **Electron 44** (Node 24.21 / Chromium 152).
2. **Fork upstream `deepseek-ai/deepseek-harness`**, using `apps/desktop` as the baseline rather than writing a shell from scratch.
3. Keep upstream's "Electron shell + `ELECTRON_RUN_AS_NODE` Host subprocess + bundled Web entry" architecture.
4. Put productization changes in a separate directory/patch set, avoiding modifications to upstream files wherever possible.

## Rationale

- **Node compatibility**: Electron bundles Node 24, satisfying dsh's `engines`; Tauri requires an additional Node sidecar.
- **Reusable assets**: updates, signing, notarization, recovery, single instance, login shell environment, directory selection, tray, and more are all already implemented.
- **UI consistency**: Chromium is pinned to a fixed version and is not affected by Linux WebKitGTK / Windows WebView2 version fragmentation.
- **Controlled risk**: upstream is already production-proven on macOS/Windows; we only need to add Linux plus branding/onboarding.
- **Ecosystem**: Electron's signing, update, crash, and DevTools toolchains are mature.

## Consequences

### Positive

- The first-version timeline drops from 6–10 months to 2–3 months (desktop MVP).
- Native module/runtime problems have upstream precedent.
- Future upstream upgrades can be followed through rebase patches.

### Negative

- Large package size (Electron + dsh deps + Python, estimated at 300–500 MB).
- High memory usage (Chromium + Node Host).
- Requires maintaining an upstream patch set; upgrades incur conflict costs.
- Electron security advisories must be followed (Chromium/Node upgrades).

### Mitigation

- Python/Office runtimes are downloaded on demand, so the initial release can be trimmed.
- Differential updates reduce download volume.
- Establish upstream sync CI: weekly rebase and smoke tests.
- Security response: subscribe to Electron security advisories and upgrade within 30 days.

## Alternatives

| Option | Why not chosen |
|---|---|
| Tauri 2 | Requires a Node sidecar; would need to rewrite the shell and update/recovery; WebView differences; upstream assets cannot be reused |
| Wails 3 | Small ecosystem; no Node; would require a rewrite |
| Qt WebEngine | High licensing/integration/package-size costs; the team is unfamiliar with it |
| Pure WebView2/WebKit | Large platform differences; no unified update/signing approach |

## Validation

- M0 prototype: Electron 44 + dsh on macOS arm64, start the Host, load the UI, and complete the token exchange; tool invocation and the bundled runtime remain to be verified.
- Package size/startup/memory baseline; comparison with a Tauri PoC (optional).
- The upstream desktop builds successfully; an unsigned DMG can be produced.

## Review Conditions

- Electron package size/memory becomes an unacceptable product problem;
- Upstream desktop stops being maintained or its license changes;
- A mature Node 24 sidecar + authentication/update solution emerges in the Tauri ecosystem;
- Enterprise customers require smaller installers/stricter sandboxing.
