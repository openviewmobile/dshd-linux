# ADR-0007: Evaluating a Fully Local Product Scope (No Remote Build)

> Note: This ADR comes from the cross-platform repository; references to documents that were not migrated with this project are retained as plain text.

- Status: Confirmed (v1): local builds for macOS/Windows/Linux/Android; iOS remains under research and is not in v1
- Date: 2026-11-08
- Deciders: Product/Architecture
- Related: ADR-0002, [ADR-0005](0005-open-source-distribution.md), ADR-0006, device-local execution research, iOS local feasibility, v1 delivery scope

## Context

The product goal changed to:

- **No remote build is offered**;
- **All platforms uniformly offer a local build**;
- The kernel remains dsh (Node + local shell/filesystem).

The question is not "can it be packaged" but: **which platforms, at the OS level, allow an app to run the full dsh kernel locally.**

## Conclusion

| Platform | Local full dsh | Assessment |
|---|---|---|
| macOS | ✅ | Electron/local Node 24; feasible |
| Windows | ✅ | Electron/local Node 24; feasible |
| Linux | ✅ | Electron/local Node 24; feasible |
| Android | ✅ (with conditions) | Cortex/PRoot + targetSdk 28; feasible but not on Play |
| iOS | ⚠️ Under research | No product-grade evidence for full L2; iSH/UTM/Node-in-process (L0/L1) pending real-device testing |
| Web | ❌ | Browsers have no local filesystem/subprocesses; a Host is required |

**Current evidence: "all six platforms fully local" at full L2 does not hold.**
If "fully local" is a hard requirement, the currently deliverable scope is: **macOS + Windows + Linux + Android**; iOS still needs a 4–8 week spike for validation and cannot be permanently removed now.
If "six platforms" is a hard requirement, then iOS/Web must either be remote or accept capability cuts along the dsh Lite/emulator route.

## 1. The Three Desktop Platforms: No Controversy

- Electron 44 + bundled Node 24 + dsh;
- Local files, bash, ripgrep, pnpm, Python, native modules;
- Signing/notarization/updates;
- GitHub Releases distribution.

This is the path already validated by the current architecture.

## 2. Android: Feasible, but Requires a Separate SKU

- Not shipping to Play allows the use of `targetSdk 28` to execute Linux binaries from the app's private directory;
- Route: Cortex (native glibc, Apache-2.0) or PRoot (mature, GPL);
- Distribution: GitHub APK / enterprise MDM;
- Costs:
  - Unknown sources/Play Protect/restricted settings;
  - 16 KB page size;
  - 1 GB-class runtime;
  - Foreground service/background kills/battery;
  - Native modules must be verified one by one;
  - GPL/rootfs licensing.

**Android is the only mobile platform that can be added under "fully local".**

## 3. iOS: An IPA Does Not Equal Local

### 3.1 System Restrictions Have Not Changed

- `fork/exec` is prohibited: bash/node/pnpm cannot be started;
- JIT is prohibited: Node/V8 can only interpret;
- Background suspension: a Host cannot stay resident;
- Sandbox: a Linux userland cannot be installed.

**Sideloading/an IPA only changes the installation method, not the above restrictions.**

### 3.2 Candidate Technical Paths (All Pending Real Testing)

| Path | Principle | Issues | Current assessment |
|---|---|---|---|
| **iSH embedding** | In-app x86 Linux emulation + syscall translation; install Node/dsh inside Alpine | GPLv3; 32-bit; no JIT; 5–100x slower; known Node illegal instructions; not an SDK | Closest to full local; requires real-device verification of Node 24 |
| **UTM SE/VM embedding** | In-app ARM64 Linux VM (QEMU interpreter) | No JIT; even slower; huge package size; background; not an SDK | Can run ARM64 Node 24; product-level performance is doubtful |
| **Node 24 in-process** | Compile Node 24 as an iOS library; no Linux userland | No `child_process`/bash/PTY; native modules must be recompiled; nodejs-mobile is Node 18 only | Most likely path to a **dsh Lite (L0/L1)** |
| **Custom lightweight Swift/JS agent** | Bypass Node/dsh and rewrite the tools | Not dsh; tools/plugins/sessions incompatible | A different product, not a local dsh |
| **jailbreak/TrollStore** | Bypass restrictions | Unsupported, insecure, unsustainable | Not doing it |

Embedding iSH could in theory let "an iPhone run Linux + Node locally", but:

- iSH is 32-bit i386; although Alpine edge x86 has Node 24.22.1, Node 24 has no official linux-x86 binary and it is a distro patch;
- iSH already has reports of Node/NPM `Illegal instruction` (Node 20+ must fall back to an older version); whether Node 24 can start must be tested on a real device;
- The performance magnitude officially cited by iSH is 5–100 times slower than native;
- GPLv3, which restricts closed-source/commercial distribution;
- An IPA can only be self-signed/Ad Hoc/enterprise, not a channel for ordinary users;
- Background kills make long tasks unreliable.

**Current assessment: there is no product-grade evidence for full L2; the iSH route cannot be declared dead just because it "can theoretically run", nor can it be treated as already feasible.**

## 4. Web: There Is No Such Thing as a "Local Kernel"

Browsers cannot:

- Start Node processes;
- Execute bash/pnpm;
- Access arbitrary local filesystems;
- Stay resident in the background.

WebAssembly also cannot provide the full Node API, subprocesses, and system tools. "Web local" only comes in two forms:

1. The browser connects to a Host on the same machine/LAN/cloud → still remote;
2. The desktop app embeds the Host and the browser is merely its UI → not a standalone Web product.

**Conclusion: no remote build means no Web build.**

## 5. Four Product Scopes

### Option A: Fully Local, Four Platforms (Recommended if "local" is a hard requirement)

| Platform | Form | Kernel |
|---|---|---|
| macOS | Desktop app | Local dsh |
| Windows | Desktop app | Local dsh |
| Linux | Desktop app | Local dsh |
| Android | Local APK | Local Cortex/PRoot + dsh |
| iOS | Not offered | — |
| Web | Not offered | — |

- Pros: truly fully local; no cloud dependency; the strongest privacy narrative.
- Cons: gives up iOS/Web; high Android maintenance cost; limited market size.
- Schedule: desktop 2–3 months; Android local 6–12 months; 9–15 months in total (3–5 people).

### Option B: Fully Local, Six Platforms + iOS/Web "Lite"

- iOS/Web do not run dsh; they use a lightweight agent (Swift/JS/WASM) or a read-only UI.
- Result: not the same kernel, not the same toolset, not the same product.
- Not recommended: users will perceive it as "crippled features", and two agents must be maintained.

### Option C: Six Platforms, but iOS/Web Remote (violates "no remote")

- Desktop/Android local; iOS/Web connect to a local Host or the cloud.
- This is the only option that preserves the full dsh on six platforms.
- If "no remote" cannot be compromised, this option does not hold.

### Option D: Force iOS with iSH/UTM

- Fine as a technical demo, not viable as a product.
- Not recommended for investment.

## 6. If Option A Is Chosen, How the Architecture Is Defined

```
┌───────────────────────────────┐
│ Unified UI / client logic     │
│ (Flutter or Electron/React)   │
└───────────────┬───────────────┘
                │ local HTTP/WS
     ┌──────────┴──────────┐
     │                     │
┌────▼──────┐      ┌─────▼──────┐
│ Desktop   │      │ Android    │
│ Electron  │      │ Cortex/    │
│ + Node 24 │      │ PRoot +    │
│ + dsh     │      │ Node 24    │
└───────────┘      └────────────┘
```

Key decisions:

- Whether to unify the UI:
  - Electron/React: desktop reuses upstream; Android uses Capacitor/Flutter;
  - Flutter: a unified UI for desktop + Android, but the protocol/shell must be rewritten;
- Android runtime: Cortex preferred (Apache-2.0, good performance), PRoot as a fallback;
- Distribution: GitHub Releases; Android APK targetSdk 28; desktop signing/notarization;
- No iOS/Web builds, no remote pairing/relay/cloud.

## 7. Costs and Risks

| Item | Estimate |
|---|---|
| Three desktop platforms | 2–3 months (reusing upstream) |
| Android local | 6–12 months (Cortex/PRoot, native modules, background, storage) |
| Unified UI (if Flutter) | +9–15 months |
| iOS local attempt | 3–6 months, and only reaches a demo |
| Web local | Not possible |
| Maintenance | Android runtime follows dsh/Node/rootfs upgrades monthly |

Main risks:

- Compatibility/security warnings of Android targetSdk 28;
- Play Protect/vendor restrictions;
- 16 KB page size;
- Native module compilation;
- Background kills;
- GPL/rootfs licensing;
- Insufficient user coverage due to the lack of iOS/Web.

## 8. Recommendations

1. **Confirm whether "fully local" outranks "six-platform coverage".**
   - If yes: choose Option A and hard-code the product scope to macOS/Windows/Linux/Android.
   - If six platforms cannot be given up: choose Option C, with iOS/Web remote.
2. **Do not force iOS local with iSH/UTM**; the return on investment is extremely poor.
3. **Validate Android before committing to it**: run dsh's Node 24, tools, native modules, and background behavior on Cortex/PRoot; invest only after it passes.
4. **UI unification can be deferred**: start with desktop Electron + Android local to validate demand; then decide on Flutter.
5. **State clearly in the docs/official website that "iOS/Web local is not supported"** to avoid mismatched user expectations.

## 9. Final Assessment

- **v1 scope: local builds for macOS/Windows/Linux/Android; no iOS/Web/remote.**
- **Fully local on four platforms (macOS/Windows/Linux/Android): feasible.**
- **Fully local on six platforms: current evidence does not support full L2.**
- **iOS local full dsh: under research; iSH/UTM can produce a demo, Node-in-process may produce an L0/L1 dsh Lite.**
- **Web local dsh: conceptually does not hold.**
- **If "no remote" is a hard constraint, the product must give up iOS/Web; if six platforms is a hard constraint, remote must be accepted.**

## Review Conditions

- Apple opens up JIT/subprocesses/local runtimes (unlikely);
- Web standards gain usable local process/filesystem capabilities (unlikely);
- The Android local runtime fails validation;
- The iOS spike completes and confirms that L0/L1 or L2 is infeasible;
- The product decides to give up iOS;
- The product decides to restore the remote build in order to keep six platforms.
