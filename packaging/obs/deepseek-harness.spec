#
# openSUSE OBS spec for DeepSeek Harness.
#
# Strategy: BINARY REPACKAGE (not a source build).
#   _service downloads the electron-builder RPM for each architecture, then this
#   spec extracts it with rpm2cpio/cpio and installs the already-built Electron,
#   Node and Python payload under /opt/deepseek-harness.  OBS re-signs the
#   resulting repository; the downloaded upstream RPM remains unsigned.
#
# Build locally:
#   osc service ra
#   osc build openSUSE_Tumbleweed x86_64
#
# Update Version/Release, the *_rpm globals, _service filenames and checksums
# atomically when a new upstream release is published.
#
%global upstream_ver 0.2.2-rc.1
%global appdir /opt/deepseek-harness
%global appimage_payload opt/DeepSeek Harness

Name:           deepseek-harness
Version:        0.2.2~rc1
Release:        0
Summary:        Electron desktop shell for a bundled dsh runtime and external plugins
License:        MIT
Group:          Development/Tools
URL:            https://github.com/deepseek-ai/deepseek-harness
Source0:        deepseek-harness-%{upstream_ver}-linux-x86_64-unsigned.rpm
Source1:        deepseek-harness-%{upstream_ver}-linux-aarch64-unsigned.rpm
ExclusiveArch:  x86_64 aarch64
BuildRequires:  cpio
BuildRequires:  rpm
BuildRequires:  desktop-file-utils
Requires:       gtk3
Requires:       mozilla-nss
Requires:       libnotify4
Requires:       libXss1
Requires:       at-spi2-core
Requires:       libXtst6
Requires:       libuuid1
Requires:       libsecret-1-0
Requires:       xdg-utils
Requires:       libxkbcommon0
Requires:       libgbm1
Requires:       libdrm2
Recommends:     libappindicator3-1
Requires(post): desktop-file-utils
Requires(post): shared-mime-info
Requires(post): gtk3-tools
Requires(postun): desktop-file-utils
Requires(postun): shared-mime-info
Requires(postun): gtk3-tools

%description
DeepSeek Harness is an Electron desktop shell for a bundled dsh runtime and
external plugins.  This package repackages the upstream prebuilt RPM.  The
Electron, Node and Python runtimes are bundled under /opt/deepseek-harness
because the desktop shell starts its Host with ELECTRON_RUN_AS_NODE; the
distribution's electron package cannot be substituted.

%prep
%setup -q -c -T

# Extract the upstream binary RPM, not the spec's own source.  The payload
# installs to /opt/DeepSeek Harness (with a space), which is normalised below.
%ifarch x86_64
rpm2cpio %{SOURCE0} | cpio -idm --quiet
%endif
%ifarch aarch64
rpm2cpio %{SOURCE1} | cpio -idm --quiet
%endif

%build
# Binary repackage: nothing is compiled.

%install
install -dm755 "%{buildroot}%{appdir}"
cp -a "%{appimage_payload}/." "%{buildroot}%{appdir}/"

# The AppImage/deb/rpm payload's own /usr prefix is intentionally discarded:
# only the runtime under /opt is reused.  Wrapper, desktop file and icon are
# generated here so OBS owns those paths.
install -dm755 "%{buildroot}%{_bindir}"
cat >"%{buildroot}%{_bindir}/deepseek-harness" <<'WRAPPER'
#!/bin/sh
# Wrapper for the repackaged AppImage runtime under /opt/deepseek-harness.
set -eu
APPDIR=/opt/deepseek-harness
export APPDIR
export PATH="$APPDIR${PATH:+:$PATH}"
export LD_LIBRARY_PATH="$APPDIR/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="$APPDIR/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export GSETTINGS_SCHEMA_DIR="$APPDIR/usr/share/glib-2.0/schemas${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
exec "$APPDIR/deepseek-harness" "$@"
WRAPPER
chmod 755 "%{buildroot}%{_bindir}/deepseek-harness"

install -dm755 "%{buildroot}%{_datadir}/applications"
cat >"%{buildroot}%{_datadir}/applications/deepseek-harness.desktop" <<'DESKTOP'
[Desktop Entry]
Name=DeepSeek Harness
Comment=Electron desktop shell for a bundled dsh runtime and external plugins
Exec=/usr/bin/deepseek-harness %U
Icon=deepseek-harness
Terminal=false
Type=Application
StartupWMClass=DeepSeek Harness
MimeType=x-scheme-handler/dsh;
Categories=Development;
DESKTOP
desktop-file-validate "%{buildroot}%{_datadir}/applications/deepseek-harness.desktop"

install -Dm644 "usr/share/icons/hicolor/1024x1024/apps/deepseek-harness.png" \
  "%{buildroot}%{_datadir}/icons/hicolor/1024x1024/apps/deepseek-harness.png"

%post
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q %{_datadir}/applications || :
fi
if command -v update-mime-database >/dev/null 2>&1; then
  update-mime-database %{_datadir}/mime || :
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -t -f %{_datadir}/icons/hicolor || :
fi

%postun
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q %{_datadir}/applications || :
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q -t -f %{_datadir}/icons/hicolor || :
fi

%files
%dir %{appdir}
%{appdir}/*
%exclude %{appdir}/chrome-sandbox
%attr(4755,root,root) %{appdir}/chrome-sandbox
%{_bindir}/deepseek-harness
%{_datadir}/applications/deepseek-harness.desktop
%{_datadir}/icons/hicolor/1024x1024/apps/deepseek-harness.png

%changelog
* Mon Nov 10 2026 DeepSeek Harness Linux packaging <noreply@deepseek.com> - 0.2.2~rc1-0
- Initial OBS binary repackage of the upstream unsigned RPM.
