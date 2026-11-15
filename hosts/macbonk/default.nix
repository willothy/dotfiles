{ config, lib, pkgs, globalUserInfo, ... }: {
  imports = [
    ./homebrew.nix
  ];

  config = {
    nixpkgs = {
      config.allowUnfree = true;
      hostPlatform = "aarch64-darwin";
    };

    system.stateVersion = 4;

    system.keyboard.enableKeyMapping = true;
    system.keyboard.remapCapsLockToEscape = true;

    system.defaults = {
      finder.AppleShowAllExtensions = true;
      dock.autohide = true;
    };

    environment.pathsToLink = [ "/Applications" ];
  };
}
