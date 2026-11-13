# Copyright 2026 DeepSeek Harness Linux packaging
# Distributed under the terms of the MIT license.

EAPI=8

# Gentoo cannot encode the fourth numeric field in upstream 0.2.2-rc.1.3;
# this packaging revision maps to that release. Update the files together.
UPSTREAM_PV="0.2.2-rc.1.3"
MY_PN="deepseek-harness"

inherit desktop xdg-utils

DESCRIPTION="Electron desktop shell for the bundled dsh runtime"
HOMEPAGE="https://github.com/openviewmobile/dshd-linux"
SRC_URI="
	amd64? ( https://github.com/openviewmobile/dshd-linux/releases/download/v${UPSTREAM_PV}/${MY_PN}-${UPSTREAM_PV}-linux-x86_64-unsigned.AppImage -> ${PF}-amd64.AppImage )
	arm64? ( https://github.com/openviewmobile/dshd-linux/releases/download/v${UPSTREAM_PV}/${MY_PN}-${UPSTREAM_PV}-linux-arm64-unsigned.AppImage -> ${PF}-arm64.AppImage )
"

S="${WORKDIR}"

LICENSE="MIT BSD PSF-2 Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# The AppImage already contains Electron 44, Node 24 and Python.  System
# Electron cannot be used: the desktop shell starts its Host with
# ELECTRON_RUN_AS_NODE.  These are runtime libraries only.
RDEPEND="
	app-accessibility/at-spi2-core
	dev-libs/expat
	app-crypt/libsecret
	dev-libs/glib
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	virtual/libcrypt:=
	virtual/libudev
	virtual/zlib
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
"

BDEPEND="media-gfx/imagemagick"

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

	local appimage="${PF}-${appimage_arch}.AppImage"
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

	# Portage runs with umask 077; the extracted tree would otherwise remain
	# unreadable by unprivileged users on a fresh install.
	chmod -R a+rX "${ED}/opt/deepseek-harness" || die

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
if [ "$(id -u)" = 0 ] || ! unshare -Ur true 2>/dev/null; then set -- --no-sandbox "$@"; fi
exec "$APPDIR/deepseek-harness" "$@"
EOF
	exeinto /usr/bin
	newexe "${T}/${MY_PN}" "${MY_PN}"

	cat >"${T}/${MY_PN}.desktop" <<'EOF' || die
[Desktop Entry]
Name=DeepSeek Harness
Comment=Electron desktop shell for a bundled dsh runtime and external plugins
Exec=/usr/bin/deepseek-harness %U
Icon=com.deepseek.harness
Terminal=false
Type=Application
StartupWMClass=com.deepseek.harness
MimeType=x-scheme-handler/dsh;
Categories=Development;
EOF
	insinto /usr/share/applications
	newins "${T}/${MY_PN}.desktop" com.deepseek.harness.desktop

	# hicolor registers 16..512, and KDE resolves the Wayland app_id through
	# the matching desktop file. Install both the correct name and the sizes.
	local icon_src="${appdir}/usr/share/icons/hicolor/1024x1024/apps/${MY_PN}.png"
	local icon_size
	for icon_size in 16 22 24 32 48 64 128 256 512; do
		convert "${icon_src}" -resize "${icon_size}x${icon_size}" "${T}/${MY_PN}-${icon_size}.png" || die
		newicon -s "${icon_size}" "${T}/${MY_PN}-${icon_size}.png" com.deepseek.harness.png
	done
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
