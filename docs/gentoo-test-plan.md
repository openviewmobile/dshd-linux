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
stat -c '%U %G %a %n' /opt/deepseek-harness/chrome-sandbox
ls -l /usr/bin/deepseek-harness
ls -l /usr/share/applications/deepseek-harness.desktop
ls -l /usr/share/icons/hicolor/1024x1024/apps/deepseek-harness.png
```

Pass criteria:

- `chrome-sandbox` is `root:root` and mode `4755`;
- `/opt/deepseek-harness` is about 1.1 GB;
- desktop file and icon are installed;
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

Use a disposable VM with `PORTAGE_TMPDIR` on a `noexec` mount:

```bash
sudo mkdir -p /var/tmp/dshd-noexec
sudo mount -t tmpfs -o noexec,nosuid,nodev tmpfs /var/tmp/dshd-noexec
sudo PORTAGE_TMPDIR=/var/tmp/dshd-noexec emerge -av app-misc/deepseek-harness-bin
```

Record whether `src_unpack` fails when executing the AppImage. This is a known
limitation; do not work around it by mounting `exec` without documenting it.

### `/opt` with `nosuid`, or `FEATURES=-suid`

Test a normal user launch when `chrome-sandbox` cannot be setuid:

```bash
# Only in a disposable VM with /opt on a nosuid mount
sudo env FEATURES="-suid" emerge -av app-misc/deepseek-harness-bin
```

Check the wrapper's fallback:

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
- tray icon behavior;
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
