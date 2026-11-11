# Release checklist

Use this before publishing a GitHub Release. Check items only when the
corresponding command/output exists in `evidence/` or in the release PR.

## 1. Version and scope

- [ ] Upstream desktop version and packaging version match; AUR `pkgver` uses
  `_` instead of `-`.
- [ ] `CHANGELOG.md` has an entry for the version.
- [ ] Release notes exist under `docs/releases/`.
- [ ] No unverified channel is described as “installed” or “launched”.

## 2. Build matrix

- [ ] x86_64: AppImage, deb, rpm, Flatpak.
- [ ] aarch64: AppImage, deb, rpm, Flatpak.
- [ ] `SHA256SUMS` regenerated in every `dist/*` directory.
- [ ] AUR package built and, when possible, installed/launched.
- [ ] Snap built; `snap install` attempted if a snapd host is available.
- [ ] OBS spec built with `rpmbuild`; OBS service build attempted if available.
- [ ] Nix/Gentoo builds attempted where the toolchain exists; otherwise marked
  “not built”.

## 3. Smoke and acceptance

- [ ] AppImage starts under Xvfb and on a real desktop.
- [ ] deb/rpm install and start; `chrome-sandbox` mode is correct.
- [ ] Flatpak x64/arm64 install and start with runtime 25.08.
- [ ] Real-provider chat round trip (no mock).
- [ ] Office export: DOCX, PPTX, XLSX, DOC, XLS, PPT; rendered pages checked.
- [ ] Third-party plugin loaded during export test.
- [ ] No secrets in logs or screenshots.

## 4. Signing

- [ ] `scripts/sign-artifacts.sh` run with the release fingerprint.
- [ ] `scripts/verify-artifacts.sh` passes for every directory.
- [ ] `keys/deepseek-harness-release-signing.asc` is the expected fingerprint.
- [ ] Fingerprint published in release notes and `docs/release-signing.md`.
- [ ] Private key and revocation certificate backed up offline; not committed.

## 5. Repository hygiene

- [ ] `LICENSE`, `NOTICE`, `LICENSES/MIT-DeepSeek-Harness.txt`,
  `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` present.
- [ ] `.github/` templates and CI pass.
- [ ] `python3 scripts/check-doc-links.py` passes.
- [ ] `git status` contains no `dist/` artifacts, private keys, or credentials; the public key under `keys/` is intentionally tracked.
- [ ] `git log` commits are signed off.
- [ ] Repository description, topics, and homepage set on GitHub.

## 6. Publish

- [ ] Create tag `v0.2.2-rc.1` (annotated) from the release commit.
- [ ] Draft GitHub Release with notes from `docs/releases/`.
- [ ] Upload artifacts + `.asc` + `SHA256SUMS` + `SHA256SUMS.asc` + the public key.
- [ ] Mark as “pre-release” for an rc.
- [ ] Verify a fresh download with the published key.
- [ ] Announce with the known-limitations section included.

## 7. Post-release

- [ ] Open tracking issues for unverified channels (Snap install, OBS service,
  Nix/Gentoo builds, Wayland/tray/IME).
- [ ] Rotate key before expiry or on compromise.
- [ ] Archive build logs and evidence for the tag.
