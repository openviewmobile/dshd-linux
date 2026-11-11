# ADR-0005: Open Source on GitHub + Distribution of Prebuilt Installers

> Note: This ADR comes from the cross-platform repository; references to documents that were not migrated with this project are retained as plain text.

- Status: Proposed; the distribution channels section is being revised/evaluated by ADR-0006

- Date: 2026-11-08
- Deciders: Product/Architecture
- Related: [ADR-0001](0001-electron-desktop.md), ADR-0002, [ADR-0003](0003-fork-upstream.md), release matrix, device-local execution research

> Note: If ADR-0006 is adopted, iOS switches to IPA sideloading and Android switches to APK-only distribution; the channel descriptions in this document for "iOS App Store/TestFlight, Android Play" no longer apply, while the remaining signing/supply-chain/licensing principles still apply.

## Context

The project plans to:

- Open source on GitHub;
- Provide compiled installers that ordinary users can download and use immediately;
- Run the dsh kernel locally on desktop;
- Explore a device-local kernel on Android;
- Possibly offer a remote companion mode for iOS/Android as well.

This differs from "ship source only and let users build it themselves": it requires handling **licensing, signing, notarization, updates, supply chain, store rules, and the installation experience for ordinary users** at the same time.

## Decision

### 1. Code Licensing

1. **Self-owned code is recommended to default to Apache-2.0** (pending final legal/product confirmation):
   - Patent grant, goodwill clause, compatible with the MIT upstream;
   - Facilitates adoption by companies/enterprises and community contributions.
2. Retain the **MIT** copyright and license notices of the dsh upstream; the forked `apps/desktop` code likewise remains MIT.
3. Do not use GPL as the default license; GPL runtimes (PRoot, Termux, etc.) are **isolated as separate runtime packs**, with source obligations fulfilled under the GPL, subject to legal confirmation.
4. **Do not use the DeepSeek name/graphics/official service marks** as product branding; state "unofficial, based on dsh" in the README and retain the upstream trademark notice.

> Alternative: If the project wants to mandate contributing back to the community, GPLv3 is an option; however, GPLv3 carries a conflict risk with the additional restrictions of the iOS App Store and would reduce enterprise willingness to adopt. If the Android local runtime must use PRoot/Termux, GPLv3 is the least troublesome compliance path, but the iOS remote client should be isolated from the GPL runtime.

### 2. Distribution Channels

| Platform | Primary channel | Installer | Notes |
|---|---|---|---|
| macOS | GitHub Releases + official website download page | Signed/notarized DMG, ZIP | Must pass Gatekeeper |
| Windows | GitHub Releases + official website download page | Authenticode-signed NSIS `.exe` | SmartScreen reputation |
| Linux | GitHub Releases + official website download page | AppImage, deb, checksums/GPG | No OS-enforced signing |
| Android local build | **GitHub Releases APK** | targetSdk 28, local runtime | Cannot be published to Play |
| Android remote build | Google Play (optional) + GitHub APK | latest target, companion client | Separate SKU from the local build |
| iOS | **App Store / TestFlight** | `.ipa` for the store/testing only | GitHub cannot install apps for ordinary users |
| Web | Self-hosted Docker / GitHub Pages static shell | Container image/static files | Kernel runs on the server |

**Key conclusion**: GitHub Releases works for desktop and Android APKs, but is **not suitable for consumer iOS distribution**. iOS can still only go through the App Store/TestFlight; open source does not change this.

### 3. Signing and Notarization Are Non-Negotiable

- **macOS**: Developer ID Application certificate + Hardened Runtime + notarytool notarization + staple; an unnotarized DMG will be blocked by Gatekeeper. Open source is no exemption.
- **Windows**: Authenticode (OV/EV) signing of the installer and all EXE/DLLs; otherwise SmartScreen warnings will significantly reduce conversion among ordinary users. Timestamping is mandatory.
- **Android**: APK signing keys stored offline/in an HSM; the local and remote builds use different applicationIds/signing policies; `targetSdk 28` applies only to the local build.
- **Linux**: SHA-256 checksums + GPG signatures; AppImage built-in updates must verify signatures.
- **iOS**: Apple Distribution certificate + App Store Review; GitHub only hosts source code and verification information.

### 4. Updates and Supply Chain

1. Desktop updates go through a **signed feed** (electron-updater / Sparkle) and do not directly trust the GitHub `latest` JSON; update packages must be signature-verified.
2. The Android local build provides an in-app "check for updates → download APK → verify SHA-256/signature → launch the installer"; this requires `REQUEST_INSTALL_PACKAGES` and an explicit unknown-sources prompt.
3. GitHub Actions uses **protected environments**, OIDC, and a least-privilege `GITHUB_TOKEN`; the release job must not be triggerable by a PR.
4. Each release ships with:
   - `SHA256SUMS`;
   - `SHA256SUMS.sig` (GPG/Sigstore);
   - `sbom.spdx.json`;
   - `provenance.intoto.jsonl` (SLSA);
   - the build commit, toolchain versions, and runtime manifest.
5. Signing keys offline/in an HSM; CI receives only short-lived credentials; key rotation and revocation procedures are written into `SECURITY.md`.
6. Anti-impersonation: official domain, pinned signing fingerprints, release verification instructions; do not distribute unverified binaries through third-party file-sharing services.

### 5. The Android Local Build Is a Separate SKU

- Local build: `targetSdk 28`, Cortex-style glibc or PRoot runtime; **distributed only via GitHub APK / enterprise MDM**, not on Play.
- Remote build: latest `targetSdk`, Capacitor/Flutter companion client; can be published to Play.
- The two can share UI/business code, but **build variants, signing, store listings, and privacy disclosures are separate**.
- Do not try to make a single APK satisfy both "local kernel + Play listing"; the targetSdk/exec rules conflict.

### 6. iOS Will Not Have a Local Kernel

- Open source does not change iOS's `fork/exec`, JIT, background, and App Store 2.5.2 restrictions.
- iOS gets only a remote companion client; iSH/UTM SE serve only as external demos and do not enter product commitments.
- If future App Store rules or the EU DMA open a viable local runtime channel, evaluate it as a separate project.

## Rationale

- **Trust**: open source + reproducible builds + signing/verification reduce the concern that "a closed-source shell will take my API key".
- **Cost**: GitHub Releases has zero distribution cost; the official website only serves the download page/docs and does not run a distribution system beyond the CDN.
- **Speed**: desktop/Android can ship binaries directly without waiting for store review; iOS remains bound by the store.
- **Compliance**: open source makes it easier to satisfy the source obligations of GPL runtimes, but cannot eliminate the platform restrictions of targetSdk/App Store.
- **Ecosystem**: the community can contribute providers, tool adaptations, and docs; however, the core runtime and signing keys must remain controlled.

## Consequences

### Positive

- Desktop and Android can iterate, canary-release, and roll back quickly.
- Users/enterprises can audit the code and build it themselves.
- GitHub Issues/Discussions form the support and plugin ecosystem.
- Open-source projects more easily obtain community resources for code signing, CI, and security scanning.

### Negative

- **Support burden**: ordinary users will file "installation failed/model won't connect/blocked by antivirus" as Issues; templates, an FAQ, and diagnostic tools are needed.
- **Security exposure**: local agent + shell + API keys means a large attack surface; it requires a threat model, approvals, key management, and vulnerability response.
- **Signing costs**: Apple Developer $99/year; Windows OV/EV certificates and HSMs; Android key management; CI macOS runner costs.
- **Licensing complexity**: dsh MIT, Electron/Chromium, Cortex Apache, PRoot/Termux GPL, and the Ubuntu/Debian rootfs each carry their own obligations.
- **Brand risk**: must clearly dissociate from DeepSeek official to avoid trademark/endorsement confusion.
- **Download experience in China**: GitHub access is unstable; mirrors/object storage are needed, and mirrors must match the official checksums.

### Mitigation

- The official website provides an OS-detecting download page, with GitHub Releases as the backend; ordinary users do not face the Release page directly.
- Installers include built-in diagnostics/log export; the first-run wizard automatically detects Gatekeeper/SmartScreen/unknown sources.
- `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue templates, private vulnerability reporting.
- Branch protection, CODEOWNERS, Dependabot, CodeQL, secret scanning, 2FA.
- Separate release keys from build keys; releases require two-person review.
- GPL runtimes get a separate repository/separate archive with the corresponding source and build scripts.

## Alternatives

| Option | Pros | Cons |
|---|---|---|
| Source-only, users build it themselves | Simplest compliance, lowest cost | Contradicts "works out of the box"; unusable for ordinary users |
| GitHub Releases for all platforms | Uniform, cheap | iOS not installable; the Android local build is restricted by Play rules |
| Store-only | Good trust/installation experience | Slow review; a local kernel cannot go on Play/App Store |
| Closed source + free binaries | Protects the implementation | Users do not trust a local agent; weak community contributions |
| Open source + commercial hosting | Sustainable | Requires accounts/billing/compliance; conflicts with the "local-first" positioning |

## Validation

- M0: use GitHub Actions to build an unsigned macOS DMG + Windows NSIS + Linux AppImage, verifying the artifacts and checksums.
- M1: complete macOS signing/notarization; a GitHub Release download installs and passes Gatekeeper.
- M2: Windows Authenticode + SmartScreen observation; Android APK signing and upgrade.
- M3: generate the SBOM, Sigstore/GPG verification, and release provenance.
- M4: iOS TestFlight; confirm that GitHub is not used as an iOS installation channel.
- M5: verify the separate Android local APK (targetSdk 28) and remote build.

## Review Conditions

- The final license choice changes (Apache-2.0 ↔ GPLv3);
- Apple/Google store rules change (especially the EU DMA, iOS local runtime);
- A usable exception appears in the Android targetSdk/exec rules;
- Signing/notarization cost or failure rate becomes unacceptable;
- The community support burden exceeds what the team can bear;
- The brand/trademark holder raises an objection.
