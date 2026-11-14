final: prev: {
  capy =
    let
      version = "0.8.0";

      src = prev.fetchurl {
        url = "https://capy.ai/download/linux/x64/appimage";
        hash = "sha256-/qKrQXNQZ+WVRDQToyBdDsj4ma3gNh1vV2KPguzUsck=";
      };

      appimageContents = prev.appimageTools.extractType2 {
        pname = "capy";
        inherit version src;
      };
    in
    prev.appimageTools.wrapType2 {
      pname = "capy";
      inherit version src;

      extraInstallCommands = ''
        # Install Capy's bundled icon.
        install -Dm644 \
          ${appimageContents}/.DirIcon \
          $out/share/icons/hicolor/256x256/apps/capy.png

        # Preserve the upstream desktop entry, including
        # MimeType, StartupWMClass, and other integration.
        mkdir -p $out/share/applications

        desktopFile=$(find ${appimageContents} \
          -name '*.desktop' -print -quit)

        if [ -z "$desktopFile" ]; then
          echo "Capy desktop entry not found" >&2
          exit 1
        fi

        cp "$desktopFile" \
          $out/share/applications/capy.desktop

        # Point the launcher and OAuth callbacks at our
        # Nix-wrapped executable.
        sed -i \
          "s|^Exec=.*|Exec=$out/bin/capy %U|" \
          $out/share/applications/capy.desktop

        sed -i \
          "s|^Icon=.*|Icon=capy|" \
          $out/share/applications/capy.desktop

        # Ensure URI arguments can reach Capy.
        if grep -q '^MimeType=.*x-scheme-handler/' \
          $out/share/applications/capy.desktop; then
          sed -i \
            's|^Exec=.*|Exec='"$out"'/bin/capy %U|' \
            $out/share/applications/capy.desktop
        fi
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
