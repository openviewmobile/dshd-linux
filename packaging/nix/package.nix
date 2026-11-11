# Nix derivation for the DeepSeek Harness AppImage.
#
# This is intentionally a binary wrapper (not a nixpkgs source build): the
# upstream AppImage already contains Electron 44, Node 24 and Python, and the
# desktop shell requires ELECTRON_RUN_AS_NODE, so substituting nixpkgs' electron
# is not an option.
#
# It uses appimageTools.extractType2 for the AppImage payload and
# autoPatchelfHook to repair the interpreter/RPATH of the bundled ELF files
# against the Nix store.  The wrapper forces Chromium's user-namespace sandbox
# because setuid chrome-sandbox cannot work in a read-only Nix store.
{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  gtk3,
  glib,
  nss,
  nspr,
  libnotify,
  libXScrnSaver,
  at-spi2-core,
  libxtst,
  libsecret,
  xdg-utils,
  libxkbcommon,
  libgbm,
  libdrm,
  cups,
  pango,
  cairo,
  alsa-lib,
  expat,
  zlib,
}:

let
  pname = "deepseek-harness";
  version = "0.2.2-rc.1";

  sources = {
    x86_64-linux = {
      url = "https://github.com/deepseek-ai/deepseek-harness/releases/download/v${version}/${pname}-${version}-linux-x86_64-unsigned.AppImage";
      hash = "sha256-zZ+PyWjRJ4tvxpGZcMRyBk3D0ueWMV02RH7TI2Zqc40=";
    };
    aarch64-linux = {
      url = "https://github.com/deepseek-ai/deepseek-harness/releases/download/v${version}/${pname}-${version}-linux-arm64-unsigned.AppImage";
      hash = "sha256-yT4aTpqKZ/6PTQPjRJEaxrwWh6zXAmpX9Fyy2i1OwA0=";
    };
  };

  source = sources.${stdenv.hostPlatform.system} or (throw
    "${pname}: unsupported system ${stdenv.hostPlatform.system}; only x86_64-linux and aarch64-linux AppImages are published");

  src = fetchurl {
    inherit (source) url hash;
  };

  appimage = appimageTools.extractType2 {
    inherit pname version src;
  };

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "DeepSeek Harness";
    comment = "Electron desktop shell for a bundled dsh runtime and external plugins";
    exec = "${pname} %U";
    icon = pname;
    terminal = false;
    categories = [ "Development" ];
    mimeTypes = [ "x-scheme-handler/dsh" ];
    startupWMClass = "DeepSeek Harness";
  };
in
stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    gtk3
    glib
    nss
    nspr
    libnotify
    libXScrnSaver
    at-spi2-core
    libxtst
    libsecret
    xdg-utils
    libxkbcommon
    libgbm
    libdrm
    cups
    pango
    cairo
    alsa-lib
    expat
    zlib
  ];

  # The AppImage bundles optional native modules and a full Python tree.  Not
  # every optional shared object is present in nixpkgs; fail only on the core
  # Electron libraries, not on optional dlopen() targets.
  autoPatchelfIgnoreMissingDeps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/${pname} $out/bin

    cp -a ${appimage}/. $out/opt/${pname}/
    chmod 0755 $out/opt/${pname}/chrome-sandbox

    install -Dm644 $out/opt/${pname}/usr/share/icons/hicolor/1024x1024/apps/${pname}.png \
      $out/share/icons/hicolor/1024x1024/apps/${pname}.png

    makeWrapper $out/opt/${pname}/${pname} $out/bin/${pname} \
      --set APPDIR "$out/opt/${pname}" \
      --prefix PATH : "$out/opt/${pname}" \
      --prefix LD_LIBRARY_PATH : "$out/opt/${pname}/usr/lib" \
      --prefix XDG_DATA_DIRS : "$out/opt/${pname}/usr/share" \
      --set GSETTINGS_SCHEMA_DIR "$out/opt/${pname}/usr/share/glib-2.0/schemas" \
      --add-flags "--disable-setuid-sandbox"

    runHook postInstall
  '';

  desktopItems = [ desktopItem ];

  meta = with lib; {
    description = "Electron desktop shell for a bundled dsh runtime and external plugins";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
