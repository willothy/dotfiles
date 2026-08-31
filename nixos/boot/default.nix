{ config, pkgs, ... }:
let

in {
  imports = [
    ./bootloader.nix
    ./kernel.nix
  ];

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  # nixpkgs 26.11 flipped this default to true, silently swapping the scripted
  # stage-1 for systemd-initrd. That hangs at the splash screen here, so stay
  # on the initrd that works until the switch is debugged deliberately.
  boot.initrd.systemd.enable = false;

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
