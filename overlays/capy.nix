final: prev: {
  capy =
    let
      version = "0.8.0";

      src = prev.fetchurl {
        url = "https://capy.ai/download/linux/x64/appimage";
        hash = "sha256-/qKrQXNQZ+WVRDQToyBdDsj4ma3gNh1vV2KPguzUsck=";
      };

      appimageContents = prev.appimageTools.extract {
        pname = "capy";
        inherit version src;
      };
    in
    prev.appimageTools.wrapType2 {
      pname = "capy";
      inherit version src;

      nativeBuildInputs = with prev; [
        makeWrapper
      ];

      extraInstallCommands = ''
        # Install the bundled application icon
        install -Dm644 \
          ${appimageContents}/.DirIcon \
          $out/share/icons/hicolor/256x256/apps/capy.png

        # Create desktop entry
        mkdir -p $out/share/applications

        cat > $out/share/applications/capy.desktop <<EOF
        [Desktop Entry]
        Name=Capy
        Comment=AI coding agent
        Exec=$out/bin/capy %U
        Icon=capy
        Terminal=false
        Type=Application
        Categories=Development;IDE;
        StartupNotify=true
        EOF
      '';

      meta = with prev.lib; {
        description = "Capy AI desktop application";
        homepage = "https://capy.ai";
        license = licenses.unfree;
        platforms = [ "x86_64-linux" ];
        mainProgram = "capy";
      };
    };
}
