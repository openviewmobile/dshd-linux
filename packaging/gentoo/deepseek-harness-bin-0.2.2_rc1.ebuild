# Copyright 2026 DeepSeek Harness Linux packaging
# Distributed under the terms of the MIT license.

EAPI=8

# Upstream GitHub release tag/filename uses 0.2.2-rc.1; Gentoo version syntax
# represents the pre-release as 0.2.2_rc1 (PV above).
UPSTREAM_PV="0.2.2-rc.1"
MY_PN="deepseek-harness"

inherit desktop xdg-utils

DESCRIPTION="Electron desktop shell for a bundled dsh runtime and external plugins (binary AppImage repackage)"
HOMEPAGE="https://github.com/deepseek-ai/deepseek-harness"
SRC_URI="
	amd64? ( https://github.com/deepseek-ai/deepseek-harness/releases/download/v${UPSTREAM_PV}/${MY_PN}-${UPSTREAM_PV}-linux-x86_64-unsigned.AppImage -> ${P}-amd64.AppImage )
	arm64? ( https://github.com/deepseek-ai/deepseek-harness/releases/download/v${UPSTREAM_PV}/${MY_PN}-${UPSTREAM_PV}-linux-arm64-unsigned.AppImage -> ${P}-arm64.AppImage )
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

# The AppImage already contains Electron 44, Node 24 and Python.  System
# Electron cannot be used: the desktop shell starts its Host with
# ELECTRON_RUN_AS_NODE.  These are runtime libraries only.
RDEPEND="
	app-accessibility/at-spi2-core
	dev-libs/expat
	dev-libs/libsecret
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/util-linux
	sys-libs/zlib
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
"

# Never strip Electron/Node/Python or the bundled native modules.
RESTRICT="strip"
QA_PREBUILT="*"

src_unpack() {
	local appimage_arch
	case ${ARCH} in
		amd64) appimage_arch=amd64 ;;
		arm64) appimage_arch=arm64 ;;
		*) die "unsupported ARCH: ${ARCH}" ;;
	esac

	local appimage="${P}-${appimage_arch}.AppImage"
	cp "${DISTDIR}/${appimage}" "${WORKDIR}/${appimage}" || die
	chmod +x "${WORKDIR}/${appimage}" || die

	# AppRun supports --appimage-extract without FUSE, which is what we need in
	# the Portage sandbox.
	cd "${WORKDIR}" || die
	"./${appimage}" --appimage-extract >/dev/null || die
	[[ -x "${WORKDIR}/squashfs-root/${MY_PN}" ]] || die "unexpected AppImage layout"
}

src_install() {
	local appdir="${WORKDIR}/squashfs-root"

	dodir /opt/deepseek-harness
	cp -a "${appdir}/." "${ED}/opt/deepseek-harness/" || die

	# chrome-sandbox needs root:root + setuid when unprivileged user namespaces
	# are unavailable.  fowners/fperms are applied by Portage as root.
	fowners root:root /opt/deepseek-harness/chrome-sandbox
	fperms 4755 /opt/deepseek-harness/chrome-sandbox

	cat >"${T}/${MY_PN}" <<'EOF' || die
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
EOF
	exeinto /usr/bin
	newexe "${T}/${MY_PN}" "${MY_PN}"

	cat >"${T}/${MY_PN}.desktop" <<'EOF' || die
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
EOF
	domenu "${T}/${MY_PN}.desktop"

	doicon -s 1024 "${appdir}/usr/share/icons/hicolor/1024x1024/apps/${MY_PN}.png"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	xdg_mimeinfo_database_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	xdg_mimeinfo_database_update
}
