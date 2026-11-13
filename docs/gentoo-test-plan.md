# Gentoo verification backlog

The binary ebuild has passed `pkgcheck`, `fetch`, `clean unpack prepare install`,
`emerge -pv` and a Wayland launch. The following items are **not yet verified**
and should be tested on a disposable Gentoo VM or dedicated machine.

## P0 — real merge and unmerge

Current evidence stops at `install` into the image; it does not exercise the real
merge, `pkg_postinst`, setuid installation, or removal.

```bash
sudo emerge -av app-misc/deepseek-harness-bin

qlist -e app-misc/deepseek-harness-bin
stat -c '%a %U:%G %n' /opt/deepseek-harness
stat -c '%U %G %a %n' /opt/deepseek-harness/chrome-sandbox
ls -l /usr/bin/deepseek-harness
kiconfinder6 com.deepseek.harness
ls /usr/share/applications/com.deepseek.harness.desktop
ls -l /usr/share/applications/deepseek-harness.desktop
ls -l /usr/share/icons/hicolor/1024x1024/apps/deepseek-harness.png
```

Pass criteria:

- `/opt/deepseek-harness` is mode `755` and readable by a normal user;
- `chrome-sandbox` is `root:root` and mode `4755`;
- `/opt/deepseek-harness` is about 1.1 GB;
- `com.deepseek.harness.desktop` exists and hicolor icons resolve;
- `pkg_postinst` emits no errors;
- a normal user can launch the app.

Then unmerge:

```bash
sudo emerge -C app-misc/deepseek-harness-bin
test ! -e /opt/deepseek-harness
test ! -e /usr/bin/deepseek-harness
test ! -e /usr/share/applications/deepseek-harness.desktop
```

Check that the desktop/icon/MIME caches update and that user data under
`~/.config` / `~/.local` is not deleted.

## P1 — mount and sandbox scenarios

### `/var/tmp` with `noexec`

Portage itself rejects a `noexec` `PORTAGE_TMPDIR` before entering the ebuild:

```text
Can not execute files in /var/tmp/.../portage
Likely cause: mount option 'noexec'
```

Treat this as a documented Portage prerequisite, not an ebuild test. If a
`noexec` build directory is required, the ebuild needs a non-exec extraction path
before it can be supported.

### `/opt` with `nosuid`, or `FEATURES=-suid`

`FEATURES=-suid` does not strip the mode written by `fperms 4755`; use a
`nosuid` mount for `/opt` in a disposable VM instead. Check the wrapper's
fallback:

```bash
sh -x /usr/bin/deepseek-harness
```

The wrapper should add `--no-sandbox` when userns is unavailable. Verify a window
appears with both user namespaces enabled and disabled.

### Root launch

```bash
sudo /usr/bin/deepseek-harness
```

The wrapper should add `--no-sandbox` for UID 0. This is a safety check, not a
recommended way to use the app.

## P1 — desktop integration

On GNOME Wayland and KDE Plasma Wayland:

- native Wayland window, no XWayland fallback unless requested;
- fractional scaling;
- file picker;
- Chinese/Japanese IME;
- desktop launch from the application menu;
- `StartupWMClass=com.deepseek.harness` grouping.

Capture the session type and a screenshot for each desktop.

## P1 — application behavior

Using a real provider key in a disposable profile:

- first launch and API-key setup;
- one real model request;
- install, enable and remove a plugin;
- open DOCX, XLSX and PPTX files and convert each to PDF;
- check the generated PDF opens and is not empty;
- record whether the Office engine was bundled, already installed as a sidecar,
  or downloaded on demand;
- test offline/network-failure behavior.

Do not put real API keys in logs, screenshots, issues or the repository.

## P2 — MIME handler

The desktop file declares:

```text
MimeType=x-scheme-handler/dsh;
```

There is currently no MIME XML in the package. Test:

```bash
xdg-mime query default x-scheme-handler/dsh
xdg-open 'dsh://open'
```

If no handler is registered, either add a MIME definition or remove the
`MimeType` line; this is a packaging decision, not a runtime fix.

## P2 — arm64 physical/VM test

Only the arm64 Manifest hashes were checked. On an arm64 Gentoo system:

```bash
uname -m
sudo emerge -av app-misc/deepseek-harness-bin
/usr/bin/deepseek-harness
```

Verify install, launch, a real request and Office conversion. Record the kernel,
glibc, Portage and pkgcheck versions.

## P2 — libcrypt on a minimal system

The ebuild now depends on `virtual/libcrypt:=`. On a minimal Gentoo image:

```bash
ldd /opt/deepseek-harness/resources/runtime/primary-runtime/dependencies/python/lib-dynload/_crypt*.so
```

Confirm `libcrypt.so.1` resolves, and test Python `import crypt` through the
bundled runtime.

## Evidence to attach to the test result

- `emerge --info` and `pkgcheck --version`;
- `pkgcheck scan` output;
- merge/unmerge log;
- `stat`/`ls` output for `/opt`, wrapper, desktop and icon;
- desktop session type and screenshots;
- exact Office/plugin/provider steps and results;
- any error logs with secrets redacted.
