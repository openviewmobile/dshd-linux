# Governance

DSHD for Linux is an independent packaging and distribution project. It is not
the official DeepSeek Harness source tree and does not claim upstream ownership.

## Maintainers

- Repository owner and release maintainer: [@openviewmobile](https://github.com/openviewmobile)

Maintainers are responsible for review, merges, releases, security response,
and keeping packaging claims consistent with evidence. The current project has
a single maintainer; additional maintainers may be added through the process
below.

## Roles

- **Contributors** open issues and pull requests, provide reproducible logs, and
  follow [CONTRIBUTING.md](CONTRIBUTING.md) and the
  [Code of Conduct](CODE_OF_CONDUCT.md).
- **Maintainers** review changes, manage releases and secrets, and handle
  private security reports.
- **Security reporters** use the private advisory flow in [SECURITY.md](SECURITY.md).

## Decisions

- Small fixes use lazy consensus in the pull request.
- Larger changes should start as an issue describing the user problem, the
  affected distributions, and the evidence plan.
- If consensus is unclear, the maintainer makes the final decision and records
  the rationale in the issue or pull request.
- Security fixes and release-key handling may be decided privately.
- Changes to this document, release policy, or maintainer roles require a
  public pull request.

## Releases and release authority

- Releases are cut from `main` after CI passes.
- Public binaries are built and signed by GitHub Actions; local binaries are
  never uploaded to a public release. See [docs/release.md](docs/release.md).
- Release tags use the versioning rules in [docs/versioning.md](docs/versioning.md).
- The release signing key and repository secrets are held by the maintainer and
  are never committed. The public key is in `keys/`.
- Release notes must state what was tested and what remains unverified.

## Security

Private vulnerability reports are handled through GitHub private advisories.
Maintainers aim to acknowledge reports within 7 days and coordinate disclosure
after a fix is available. Do not open a public issue containing exploit details.

## Continuity

The maintainer keeps release-key recovery material and repository access
documented offline. If the project becomes inactive, the public key and release
history remain available so users can verify existing artifacts, but no new
updates should be assumed.

## Code of conduct

Participation is covered by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
Enforcement reports should use the private maintainer channel, not a public
issue.
