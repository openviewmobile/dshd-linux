# Security policy

## Supported versions

Security fixes are provided for the current release candidate and the latest
stable release line. Older release candidates are not supported.

| Version | Supported |
|---|---|
| 0.2.2-rc.1 | Yes (release candidate) |
| < 0.2.2-rc.1 | No |

## Reporting a vulnerability

Please do **not** open a public issue for a vulnerability. Open this
repository's **Security** tab, choose **Advisories**, and use **Report a
vulnerability** to start a private advisory. If the advisory flow is not enabled
yet, ask a maintainer for a private channel before sharing details.

Include the affected version, architecture, distro, a minimal reproduction, and
the impact. If the advisory flow is unavailable, contact a maintainer through
the repository's private maintainer channel and ask for a secure exchange.

We aim to acknowledge reports within 7 days and to publish a coordinated fix
and advisory when a fix is ready. Please give us reasonable time before public
disclosure.

## Scope

In scope:

- the Linux desktop wrapper, launcher scripts and packaging;
- update/release signature verification;
- sandbox/permission behavior in AppImage, deb, rpm, Flatpak, Snap and AUR;
- Office/PDF conversion handling of untrusted input (LibreOfficeKit WASM);
- credential handling in the desktop application.

Out of scope:

- vulnerabilities in upstream Electron/Chromium/Node that are not exploitable
  through this packaging;
- social engineering or physical access;
- issues that require the user to disable the sandbox or install untrusted
  plugins knowingly.

## Release integrity

Every published artifact has a detached GPG signature (`.asc`) next to it, and
each directory has a signed `SHA256SUMS`. Verify both before installing:

```bash
gpg --import keys/deepseek-harness-release-signing.asc
gpg --verify SHA256SUMS.asc SHA256SUMS
sha256sum -c SHA256SUMS
```

The public key fingerprint is documented in
[docs/release-signing.md](docs/release-signing.md). A valid signature only
proves the artifact came from the holder of the release key; it is not a
platform code-signing certificate.
