{ config, pkgs, ... }:
let

in {
  imports = [
    ./bootloader.nix
    ./kernel.nix
  ];

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  # Nice boot screen
  boot.plymouth = {
    enable = true;
    # theme = "catppuccin-mocha";
    # themePackages = with pkgs; [
    #   (catppuccin-plymouth.override {
    #     variant = "mocha";
    #   })
    # ];
  };
}
