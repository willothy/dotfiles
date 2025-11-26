{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./refind-theme.nix
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    bootloader = "refind";
    pkiBundle = "/var/lib/sbctl";

    refind = {
      extraConfig = ''
        resolution 0

        hideui singleuser,hints,arrows,badges,safemode,hwtest

        use_graphics_for osx,linux,elilo,grub,windows

        icons_dir themes/refind/assets/mocha/icons

        banner themes/refind/assets/mocha/background.png

        banner_scale fillscreen

        selection_big   themes/refind/assets/mocha/selection_big.png
        selection_small themes/refind/assets/mocha/selection_small.png

        scanfor internal,external,manual
        dont_scan_volumes NIX-BOOT
        dont_scan_dirs EFI/linux, EFI/nixos, EFI/ubuntu, EFI/systemd, EFI/BOOT
      '';

      extraFiles = inputs.lanzaboote.lib.fetchRefindTheme {
        inherit lib pkgs;

        owner = "catppuccin";
        repo = "refind";
        rev = "main";
        sha256 = "sha256-34+MkvWEp3xq6Di1uWKR4ieaG4t2rufnRRN1/V0WRfw=";
      };
    };
  };

  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.systemd-boot = {
    # enable = true;
    consoleMode = "max";
    windows = {
      win11 = {
        sortKey = "0"; # alway first
        title = "Windows 11";
        efiDeviceHandle = "HD3b";
      };
    };

    # Used to get the efiDeviceHandle
    # edk2-uefi-shell.enable = true;
  };

  boot.loader.grub = {
    enable = false;
  };

  boot.loader.refind = {
    enable = false;
    themes = {
      catppuccin = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "refind";
        rev = "main";
        sha256 = "sha256-34+MkvWEp3xq6Di1uWKR4ieaG4t2rufnRRN1/V0WRfw=";
      };
    };
    overrideEntry = {
      catppuccin = "custom.conf";
    };
    theme = "catppuccin";
    # maxGenerations = 100;
    # refindgen = {
    #   enable = false;
    # };
    extraConfig = ''
      resolution 0

      hideui singleuser,hints,arrows,badges,safemode,hwtest

      use_graphics_for osx,linux,elilo,grub,windows

      icons_dir themes/catppuccin/assets/mocha/icons

      banner themes/catppuccin/assets/mocha/background.png

      banner_scale fillscreen

      selection_big   themes/catppuccin/assets/mocha/selection_big.png
      selection_small themes/catppuccin/assets/mocha/selection_small.png

      dont_scan_volumes NIX-BOOT
      dont_scan_dirs EFI/nixos, EFI/ubuntu, EFI/systemd, EFI/BOOT
    '';
    # in
    # {
    #   "efi/refind/themes/catppuccin/custom.conf" = themeConfig;
    # };
  };
}
