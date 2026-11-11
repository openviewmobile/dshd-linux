# ADR-0003: Fork the Upstream Repository Instead of Rewriting the Desktop Shell from Scratch

> Note: This ADR comes from the cross-platform repository; references to documents that were not migrated with this project are retained as plain text.

- Status: Proposed
- Date: 2026-11-08
- Deciders: Architecture Group
- Related: [ADR-0001](0001-electron-desktop.md), [Target Architecture](../architecture.md)

## Context

The upstream `deepseek-ai/deepseek-harness` is an MIT-licensed monorepo containing:

- `apps/desktop`: the Electron shell, productionized for macOS/Windows;
- `apps/desktop-host`: the private Host for Electron RunAsNode;
- `apps/cli`: the dsh CLI;
- `packages/*`: 300+ packages (agent, tools, Web UI, plugins);
- Packaging scripts: runtime preparation, Python/pnpm, signing, notarization, updates, recovery.

Writing an Electron shell from scratch takes only a few hundred lines, but reaching "consumer-grade releasable" requires redoing all of the above platform work.

## Decision

1. Maintain the code using **fork + upstream remote**:
   - `upstream` points to `deepseek-ai/deepseek-harness`;
   - Pin a tag (e.g., `dsh-v0.2.2-rc.1`);
   - Keep productization changes in `products/dshd` or `patches/` wherever possible.
2. Do not copy the upstream code into a "new repository with no history"; retain the git history to enable rebasing.
3. Run desktop smoke tests and signing verification for every upstream version upgrade.
4. If the upstream license/maintenance policy changes, keep a "minimal in-house shell" as the exit path.

## Rationale

- **Time**: reusing the productionized shell gives a desktop MVP in 2–3 months; from scratch takes 6–10 months.
- **Quality**: upstream already handles signing, notarization, updates, recovery, single instance, login shell, and runtime verification.
- **Cost**: 70+ platform files and CI scripts that do not need to be maintained.
- **Risk**: MIT permits forking; however, branding/official services must be replaced.

## Consequences

### Positive

- Fast delivery; platform details are backed by upstream.
- Upstream security/compatibility fixes can be obtained through rebasing.
- The team focuses on branding, onboarding, mobile, and distribution.

### Negative

- Requires maintaining a patch set; upstream refactors will cause conflicts.
- The upstream monorepo is large (pnpm workspace, hundreds of packages), so builds are slow.
- Upstream may be coupled to official accounts/telemetry/update policies, which must be stripped out.
- Branding and official services are not covered by the MIT license.

### Mitigation

- Minimize patches; keep product code in a separate package; have CI check that patches apply.
- Pin upstream versions and upgrade quarterly; do not track master.
- Establish an "upstream change board": security, API, desktop, Web.
- Legal review of branding/third-party licenses (Electron, Python, LibreOffice, fonts).

## Alternatives

| Option | Pros | Cons |
|---|---|---|
| Write an Electron shell from scratch | Code is controllable; package size can be trimmed | 6–10 months; many platform pitfalls; updates/signing/recovery must be redone |
| Use the official Desktop directly + plugins | Fastest | Cannot rebrand/customize first-run/mobile; depends on official services |
| Web + PWA only | Simplest | No local files/terminal; does not meet desktop app requirements |
| Tauri rewrite | Small package size | Requires a Node sidecar; upstream assets cannot be reused |

## Validation

- M0: clone upstream, build the macOS desktop, and produce an unsigned DMG.
- Apply one branding patch (app name/icon/about page) and confirm that the patch set is maintainable.
- Upgrade to the next rc and measure rebase conflicts and smoke-test time.

## Review Conditions

- Upstream desktop is no longer maintained/license changes;
- Patch conflict costs exceed the cost of in-house development;
- The product requires large-scale trimming (e.g., removing Python/Office/plugins), making the fork a burden instead;
- Branding/legal requirements demand a fully independent codebase.
