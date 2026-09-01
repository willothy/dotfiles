{ config, pkgs, ... }:
let

in {
  imports = [
    ./bootloader.nix
    ./kernel.nix
  ];

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  # The initrd carries the nvidia modules for early KMS, which pushes it to
  # ~118MB. The firmware reads all of that off the ESP before the kernel
  # starts - that is the blank screen between rEFInd and the splash, and none
  # of it shows up in systemd-analyze. Compression is a build-time cost paid
  # once, so take the smallest file zstd will give us.
  boot.initrd.compressorArgs = [
    "-19"
    "-T0"
  ];

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
