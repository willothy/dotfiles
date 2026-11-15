{ config, lib, pkgs, globalUserInfo, ... }: {
  imports = [
    ./homebrew.nix
  ];

  config = {
    nix = {
      enable = false;
      gc = {
        interval = {
          Weekday = 0;
          Hour = 2;
          Minute = 0;
        };
        options = "--delete-older-than 30d";
      };
      package = lib.mkForce pkgs.nix;
    };
    nixpkgs = {
      config.allowUnfree = true;
      hostPlatform = "aarch64-darwin";
    };
    # services.nix-daemon.enable = true;

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
