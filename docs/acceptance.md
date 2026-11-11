# Linux Desktop Acceptance Record (2026-11-10)

> Environment: x64 deb `deepseek-harness-0.2.2-rc.1`, Debian bookworm container + Xvfb 1440×900,
> Electron 44.7.0 / Node 24.21.0. The provider is a real OpenAI-compatible gateway on the LAN
> (`newapi-gateway` / `deepseek-v4.1-flash`); the API key is supplied by the local
> `~/.dsh/.credentials.yaml` and is never written into the repository.
>
> CJK fonts were installed in the container specifically for acceptance; this is a test-environment
> difference, not an application dependency. In the container, Electron requires
> `--no-sandbox --disable-gpu --disable-dev-shm-usage`.

## 1. Conversation with a Real Provider

| Item | Result |
|---|---|
| Provider | Custom OpenAI Chat Completions (Settings → Models → Custom model API) |
| Model | `deepseek-v4.1-flash` |
| Prompt | “Reply with only one line: DSHD-LINUX-PROVIDER-OK, then write out the result of 17*23.” ([exact original](../evidence/provider-prompt.txt)) |
| Response | `DSHD-LINUX-PROVIDER-OK 391` |
| Latency / usage | 2 s; 9.8K tok; 131 tok/s |
| Evidence | [linux-provider-e2e.png](../evidence/linux-provider-e2e.png), [provider-e2e.json](../evidence/provider-e2e.json) |

This call went through the full chain: Electron → bundled Node → dsh Host → custom provider → LAN
gateway → streamed model response → Web UI rendering. It is not a mock, and it does not merely test
`/v1/models`.

## 2. Office → PDF (Built-in WASM Engine)

The Linux package already bundles `@deepseek-ai/libreoffice-kit-wasm@0.1.5`. `selectOfficeEngine()`
selects `wasm` on Linux, so system LibreOffice is not required, nor does it depend on the upstream
`libreoffice-kit-linux-*` native packages that are missing.

| Format | Output | Time | File header | SHA-256 (first 16 chars) |
|---|---|---|---|---|
| DOCX | 12,461 B | 5 s | `%PDF-` | `81fe3f11de01dd2d` |
| XLSX | 11,633 B | 4 s | `%PDF-` | `b7283d17040e23bd` |
| PPTX | 11,479 B | 6 s | `%PDF-` | `1b01df0650fd42c3` |

Full hashes, missing fonts, and commands are in [office-wasm.txt](../evidence/office-wasm.txt).

### 2.1 In-session Skill Invocation

In a real session, the agent was asked to use `office-export-pdf`:

1. The skill reports the absolute paths of the packaged Node and `libreoffice-kit/lib/cli.js`;
2. The CLI reports `{"runtime":{"backend":"wasm"},...}` and completes the conversion;
3. It produces `/root/dshd-office-acceptance.pdf`, 12,099 B, with a `%PDF-` header;
4. Screenshot: [linux-pdf-export.png](../evidence/linux-pdf-export.png).

### 2.2 In-UI PDF Preview

After showing a PDF with `present`, clicking the file card opens a preview tab on the right:

- The tab path and zoom (67%) and single-page rendering are normal;
- The text layer is readable (`DSHD Linux Office PDF acceptance 391`);
- Screenshot: [linux-pdf-preview.png](../evidence/linux-pdf-preview.png).

The same PDF can also be opened from the **Files** panel on the right, forming a separate
"file browser → PDF preview" path; see
[linux-pdf-preview-files.png](../evidence/linux-pdf-preview-files.png).

Conclusion: the entire PDF chain — "generate → present in session → file browser/session card → UI
preview" — works.

### 2.3 Legacy Binary Office Formats (Format by Format)

Using Apache POI test fixtures (commit `cdcdcf18`, real OLE2 files that `file` identifies as
Composite Document), each format was converted in turn on the same
`@deepseek-ai/libreoffice-kit` WASM backend as the packaged deb; `convert` returned `backend=wasm`
and `missingFonts=[]`, and `render` was then used to render and check the content page by page.

| Format | Input | Output | Pages | Evidence |
|---|---|---|---|---|
| DOC | `SampleDoc.doc`, 27 KB | `SampleDoc.pdf`, 21 KB | 2 | [PDF](../evidence/legacy-office/SampleDoc.pdf), [page 1](../evidence/legacy-office/SampleDoc-page1.png) |
| XLS | `1900DateWindowing.xls`, 6 KB | `1900DateWindowing.pdf`, 9.9 KB | 1 | [PDF](../evidence/legacy-office/1900DateWindowing.pdf), [page 1](../evidence/legacy-office/1900DateWindowing-page1.png) |
| PPT | `SampleShow.ppt`, 123 KB | `SampleShow.pdf`, 28 KB | 2 | [PDF](../evidence/legacy-office/SampleShow.pdf), [page 1](../evidence/legacy-office/SampleShow-page1.png) |

The rendered pages respectively show “I am a test document / This is page 1”, the date “01/01/2000”,
and the titles “Title of the first slide / Subtitle of the first slide”. Fixture sources, SHA-256
values, commands, and the per-page manifest are in
[legacy-office/README.txt](../evidence/legacy-office/README.txt).


## 3. Screen-by-Screen Acceptance

| # | UI / Feature | Result | Evidence |
|---|---|---|---|
| 1 | Welcome screen (Sign in / Add API Key) | Passed | [linux-ui-01-welcome.png](../evidence/linux-ui-01-welcome.png) |
| 2 | Add API Key on first launch | Passed; known UX gap: no Base URL | [linux-ui-02-provider.png](../evidence/linux-ui-02-provider.png) |
| 3 | Empty home page / select workspace | Passed | [linux-ui-03-home.png](../evidence/linux-ui-03-home.png) |
| 4 | Workspace directory picker | Passed | [linux-ui-workspace-picker.png](../evidence/linux-ui-workspace-picker.png) |
| 5 | New session / model selector | Passed | §1 of this document |
| 6 | Real conversation + tool calls + usage | Passed | [linux-provider-e2e.png](../evidence/linux-provider-e2e.png) |
| 7 | PDF export (DOCX) | Passed | [linux-pdf-export.png](../evidence/linux-pdf-export.png) |
| 7a | PDF export (PPTX, UI + preview) | Passed, 11,479 B, `%PDF-` | [linux-pdf-pptx-preview.png](../evidence/linux-pdf-pptx-preview.png) |
| 7b | PDF export (XLSX, UI + preview) | Passed, 11,633 B, `%PDF-` | [linux-pdf-xlsx-preview.png](../evidence/linux-pdf-xlsx-preview.png) |
| 8 | PDF preview tab | Passed | [linux-pdf-preview.png](../evidence/linux-pdf-preview.png) |
| 8b | Files panel → PDF preview | Passed | [linux-pdf-preview-files.png](../evidence/linux-pdf-preview-files.png) |
| 8c | Workspace files panel | Passed | [linux-ui-workspace-files.png](../evidence/linux-ui-workspace-files.png) |
| 9 | Plugins page (built-in settings + experimental plugins) | Passed | [linux-ui-plugins.png](../evidence/linux-ui-plugins.png) |
| 10 | Third-party plugin install (`dsh-plugin-whale-pet@0.2.9`) | Passed | [linux-ui-plugin-enabled.png](../evidence/linux-ui-plugin-enabled.png) |
| 11 | Third-party plugin details / version / update check | Passed | [linux-ui-plugin-detail.png](../evidence/linux-ui-plugin-detail.png) |
| 12 | Third-party plugin uninstall confirmation | Passed | [linux-ui-plugin-uninstall-confirm.png](../evidence/linux-ui-plugin-uninstall-confirm.png) |
| 13 | Desktop pet after enabling the plugin | Passed (small whale on the right) | [linux-ui-plugin-enabled.png](../evidence/linux-ui-plugin-enabled.png) |
| 14 | Full plugin install/enable/uninstall loop | Passed (2026-11-08 baseline) | [linux-ui-06…11](../evidence/) |
| 15 | Settings General | Passed | [linux-ui-settings-general.png](../evidence/linux-ui-settings-general.png) |
| 16 | Settings Models | Passed | [linux-ui-settings-models.png](../evidence/linux-ui-settings-models.png) |
| 17 | Add third-party model provider (catalog) | Passed | [linux-ui-settings-add-provider.png](../evidence/linux-ui-settings-add-provider.png) |
| 18 | Custom model API form | Passed | [linux-ui-settings-custom-provider.png](../evidence/linux-ui-settings-custom-provider.png) |
| 19 | Settings Built-in plugins (component list) | Passed | [linux-ui-settings-builtin-plugins.png](../evidence/linux-ui-settings-builtin-plugins.png) |
| 20 | Settings Agent presets (Standard/PTC/Minimal/Creator) | Passed | [linux-ui-settings-agent-presets.png](../evidence/linux-ui-settings-agent-presets.png) |
| 21 | Keyboard shortcut editor | Passed | [linux-ui-settings-shortcuts.png](../evidence/linux-ui-settings-shortcuts.png) |
| 22 | Automation tasks list / create | Passed (can create from an empty list) | [linux-ui-automation.png](../evidence/linux-ui-automation.png) |
| 23 | Account menu (Settings / Feedback / Sign in) | Passed | [linux-ui-more-menu.png](../evidence/linux-ui-more-menu.png) |
| 24 | Composer menu (permissions / model / export) | Passed | [linux-ui-composer-menu.png](../evidence/linux-ui-composer-menu.png) |
| 25 | Session log export (ZIP) | UI present; not accepted by unpacking every file | Same as above |
| 26 | Multiple tabs / split view / right sidebar | UI present; combined paths not accepted | — |
| 27 | Error recovery page (renderer crash) | Renders; abnormal path | Encountered this time, see §5 |

> Note: screenshots for items 15–21 come from the same session; some overlays (shortcuts) require
> pressing Esc first to close the parent panel, which is a test operation-order issue, not a product
> defect.

## 4. Plugin Compatibility

- Built-in plugins: the Settings pages for Subagent, Web search/fetch, Agent loop, Shell, etc. all
  open; the component list scrolls fully.
- Experimental plugins: Voice input, Custom plugin indexes, Auto authorization review, Change
  requests & worktrees are all visible and can be toggled.
- Third-party plugins: `dsh-plugin-whale-pet@0.2.9` installs successfully from the npm mirror; once
  enabled, the frontend injects the desktop pet, and the details page can read the version, running
  state, source, and license information.
- Plugins run inside the Host process with the same permissions as the main program; installing,
  enabling, and uninstalling do not require restarting the application.

## 4.1 Flatpak 25.08 Install/Start

- bundle: `deepseek-harness-0.2.2-rc.1-linux-x86_64-unsigned.flatpak`, 240 MiB;
- `flatpak install --user --bundle` succeeds;
- ref: `app/com.deepseek.harness/x86_64/master`;
- runtime/sdk/base: `25.08` / `25.08` / `Electron2.BaseApp 25.08`;
- metadata `command=/app/lib/com.deepseek.harness/dsh-launch`;
- Really launched under Xvfb, welcome page renders normally;
- arm64: `app/com.deepseek.harness/aarch64/master`, runtime/sdk/base likewise 25.08, metadata
  `command=/app/lib/com.deepseek.harness/dsh-launch`, welcome page launched under Xvfb;
- Evidence: [flatpak-2508-verify.txt](../evidence/flatpak-2508-verify.txt),
  [flatpak-2508-arm64-verify.txt](../evidence/flatpak-2508-arm64-verify.txt),
  [linux-flatpak-2508-start.png](../evidence/linux-flatpak-2508-start.png),
  [linux-flatpak-2508-arm64-start.png](../evidence/linux-flatpak-2508-arm64-start.png).

## 4.2 Arch / AUR Install and Start

- Package: `deepseek-harness-bin-0.2.2_rc.1-1-x86_64.pkg.tar.zst` (339 MB);
- `pacman -Udd` installation succeeds, and `pacman -Q deepseek-harness-bin` returns `0.2.2_rc.1-1`;
- After installing the dependencies `nss gtk3 pango cairo alsa-lib mesa libxkbcommon libcups libxss
  at-spi2-core libxtst libsecret xdg-utils libx11 libxcomposite libxdamage libxrandr expat zlib
  libnotify xorg-server-xvfb`, it starts successfully under Xvfb and CDP returns the `dsh-app://`
  page;
- Evidence: [linux-arch-aur-start.png](../evidence/linux-arch-aur-start.png),
  [aur-build.txt](../evidence/aur-build.txt).


## 4.3 Release Signing

- Release key fingerprint `0E6023DF4DB8C68AA2202EF876CE5675AFF067FF`, public key at
  [keys/deepseek-harness-release-signing.asc](../keys/deepseek-harness-release-signing.asc);
- All 11 artifacts plus the 5 `SHA256SUMS` files have detached `.asc` signatures, and all 16
  signatures pass `gpg --verify`;
- Record: [release-signing.txt](../evidence/release-signing.txt);
- For the verification method, private key management, and rotation, see
  [release-signing.md](release-signing.md).

## 5. Known Issues (Added by This Acceptance Round)

| Priority | Issue | Description |
|---|---|---|
| P1 | Renderer crash in the container | After the first restart, `Desktop renderer exited: crashed` appeared; stable after adding `--disable-dev-shm-usage`. This has been written into the acceptance script recommendations, but whether ordinary desktops are affected awaits confirmation on real hardware. |
| P1 | Flatpak GUI inside Docker requires a test-only bwrap wrapper | Not needed on a real host; must be re-verified on real Ubuntu/Fedora machines before release. |
| P2 | Add API Key on first launch has no Base URL | Non-technical users must skip it and then configure a custom provider under Settings→Models. |
| P2 | Chinese fonts | The container has no CJK fonts by default, so screenshots show boxes; real desktops usually ship them. The application should not depend on test-container fonts. |
| P2 | Legacy DOC/XLS/PPT | The WASM capability table claims support, but only DOCX/XLSX/PPTX were actually tested. |
| P2 | Flatpak runtime | Both x64 and arm64 have been switched to 25.08 and installation/startup is complete. |

## 6. Reproduction Commands

The real-provider E2E is scripted; use a home directory **with no conversation history** to avoid
false positives from old replies:

```bash
mkdir -p /tmp/dshd-provider-home
cp -a /tmp/dshd-e2e/home/profiles /tmp/dshd-e2e/home/.credentials.yaml \
      /tmp/dshd-e2e/home/.anonymous-user-id /tmp/dshd-provider-home/
chmod 600 /tmp/dshd-provider-home/.credentials.yaml

scripts/e2e-provider.sh dist/linux-x64/*.deb
# -> {"ok":true,"elapsedSeconds":2,"model":"Select model, current deepseek-v4.1-flash",...}
```

The script installs the deb, starts Xvfb/Electron, automatically selects the `$HOME` workspace,
sends the prompt, polls until `DSHD-LINUX-PROVIDER-OK 391` appears, and then takes a screenshot. By
default it uses the image `dshd-linux-test:amd64-e2e` (base image + deb runtime dependencies), which
can be overridden with `IMAGE=`.

Manual inspection:

```bash
docker exec dshd-e2e node /work/scripts/cdp.mjs list
docker exec dshd-e2e node /work/scripts/cdp.mjs eval 'dsh-app' 'document.body.innerText'
docker exec dshd-e2e bash -lc 'DISPLAY=:99 import -window root /work/evidence/x.png'
```

The provider configuration file lives at `/root/.dsh/profiles/desktop/cordis.patch.yml` (or `web`);
`apiKeyEnv` points to an environment variable or `~/.dsh/.credentials.yaml`; do not commit keys to
the repository.
