{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.boot.loader.refind;

  mkTheme = name: src: pkgs.stdenv.mkDerivation {
    pname = "refind-theme-${name}";
    version = "1.0";
    inherit src;

    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };

  # Function to create file mappings for all files in a theme
  mkThemeFiles = name: themePackage:
    let
      # Get all files recursively from the theme package
      getFiles = pkgs.runCommand "theme-files-${name}" { } ''
        find ${themePackage} -type f -printf "themes/${name}/%P\n" > $out
      '';

      fileList = splitString "\n" (removeSuffix "\n" (readFile getFiles));

      # Create attribute set mapping each file path to its source
      mkFileEntry = file: {
        name = file;
        value = "${themePackage}/${removePrefix "themes/${name}/" file}";
      };
    in
    listToAttrs (map mkFileEntry (filter (f: f != "") fileList));

in
{
  options.boot.loader.refind = {
    themes = mkOption {
      type = types.attrsOf types.package;
      default = { };
      description = "Available rEFInd themes";
    };

    overrideEntry = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Theme entrypoint files (defaults to theme.conf)";
      example = {
        catppuccin = "mocha.conf";
      };
    };

    theme = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Active theme name";
    };
  };

  config = mkIf (cfg.theme != null) {
    assertions = [
      {
        assertion = cfg.themes ? ${cfg.theme};
        message = "Theme '${cfg.theme}' not found in available themes";
      }
    ];

    boot.loader.refind.additionalFiles =
      let themePackage = mkTheme cfg.theme cfg.themes.${cfg.theme};
      in mkThemeFiles cfg.theme themePackage;
  };
}
