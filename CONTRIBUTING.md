# Contributing to DSHD for Linux

Thanks for helping make the Linux desktop distribution reproducible. This
repository contains the Linux target patches, packaging definitions, tests and
release evidence; the application source lives in the upstream DeepSeek
Harness repository.

## Ways to contribute

- Reproduce a build or acceptance item and report the exact commands/output.
- Improve a distro package (AUR, Snap, OBS, Nix, Gentoo) with a real build log.
- Fix documentation, links, or a test that is flaky on a supported distro.
- Report a security issue privately as described in [SECURITY.md](SECURITY.md).

## Development workflow

1. Open an issue for anything larger than a typo; describe the distro, version,
   architecture, and whether you can test on real hardware.
2. Fork the repository and create a topic branch.
3. Keep changes focused. Do not mix packaging changes with unrelated docs.
4. Run the checks that apply:
   - `python3 scripts/check-doc-links.py` (or the Python command in CI) for docs;
   - `bash -n` on every changed shell script;
   - `scripts/verify-artifacts.sh` for a local artifact set;
   - the relevant smoke script under `scripts/`.
5. Open a pull request using the template. Include commands, logs, and
   screenshots for UI changes. State what you did **not** test.

## Commit and PR expectations

- Use imperative commit subjects, for example `flatpak: restore PATH for
  zypak launch`.
- Sign off commits with the Developer Certificate of Origin (`git commit -s`).
- Do not commit secrets, API keys, provider credentials, private GPG keys, or
  generated `dist/` artifacts. `dist/` is gitignored; publish artifacts through
  a GitHub Release.
- Binary fixtures added for tests must have a clear license and provenance.
  Prefer small, publicly redistributable fixtures and record the URL and
  SHA-256 in the test README.

## Packaging changes

- A packaging change is not complete until it has a reproducible command and
  an evidence file under `evidence/`.
- Keep the package version in sync with the upstream desktop version. AUR uses
  `_` instead of `-` in `pkgver`.
- Preserve `chrome-sandbox` as `4755 root:root` for AUR/OBS/Gentoo. Snap/Nix
  use a read-only store, so their wrappers pass `--disable-setuid-sandbox`.
- Do not add a runtime dependency on a system Electron; the bundled runtime is
  required.
- Update `docs/distro-packaging-implementation.md` and the channel matrix when
  a build status changes. Mark unverified items as unverified.

## Release signing

Release artifacts are signed with a detached GPG key. Maintainers must not
commit the private key. See [docs/release-signing.md](docs/release-signing.md)
and use `scripts/sign-artifacts.sh` with `DSHD_GPG_KEY` set to the release
fingerprint.

## Community and decisions

- Read [GOVERNANCE.md](GOVERNANCE.md) for maintainer roles, lazy consensus,
  release authority, and continuity.
- Use [SUPPORT.md](SUPPORT.md) for usage questions; bugs belong in the issue
  forms.
- [ROADMAP.md](ROADMAP.md) lists current priorities and evidence needs.
- Release candidates and stable versions follow
  [docs/versioning.md](docs/versioning.md).

## License

By contributing, you agree that your contribution is licensed under the
Apache License 2.0 (see [LICENSE](LICENSE)) and that you have the right to
submit it.
