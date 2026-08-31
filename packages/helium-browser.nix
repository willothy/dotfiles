{
  stdenv,
  lib,
  appimageTools,
  fetchurl,
  makeDesktopItem,
}:
let
  pname = "helium-browser";
  version = "0.5.5.1";

  architectures = {
    "x86_64-linux" = {
      arch = "x86_64";
      hash = "sha256-FCLCt0T+U8JqUkFVAfl//OtnWsNoN8lWHIiMJws2Mqo=";
    };
    "aarch64-linux" = {
      arch = "arm64";
      hash = "sha256-KfQlOT4mMKQ40B8hWl+GlmRNVhZnEln59ptfXN0XCLc=";
    };
  };

  src =
    let
      inherit (architectures.${stdenv.hostPlatform.system}) arch hash;
    in
    fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-${arch}.AppImage";
      inherit hash;
    };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };

  desktopItem = makeDesktopItem {
    name = "helium-browser";
    desktopName = "Helium";
    exec = "helium-browser %U";
    icon = "helium-browser";
    genericName = "Web Browser";
    categories = [ "Network" "WebBrowser" ];
    mimeTypes = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${desktopItem}/share/applications/*.desktop -t $out/share/applications/

    for size in 16 32 48 64 128 256 512 1024; do
      icon="${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/helium.png"
      if [ -f "$icon" ]; then
        install -Dm444 "$icon" "$out/share/icons/hicolor/''${size}x''${size}/apps/helium-browser.png"
      fi
    done
  '';

  meta = {
    platforms = lib.attrNames architectures;
  };
}
