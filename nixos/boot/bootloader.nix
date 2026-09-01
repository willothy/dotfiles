{ config, lib, pkgs, inputs, ... }:
let
  # rEFInd as built by current nixpkgs, i.e. against gnu-efi 4 - the build this
  # firmware hangs on. Taken straight from the nixpkgs input so the refind-pin
  # overlay doesn't shadow it.
  #
  # This is installed only as manually-selected menu entries, chainloaded from
  # the working rEFInd. A failure costs a power-cycle, not a USB rescue, and
  # rEFInd reports load errors - so this distinguishes "the firmware won't load
  # the image" from "the image runs and hangs in early init".
  refindGnuEfi4 = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.refind;

  # rEFInd reads refind.conf from the directory it was loaded from, so each
  # test copy gets its own. Empty menus: drawing anything at all proves the
  # image loaded and initialised.
  mkTestConf =
    { textonly }:
    pkgs.writeText "refind-test.conf" (
      ''
        timeout 10
        use_nvram false
        scanfor manual
      ''
      + lib.optionalString textonly "textonly\n"
    );
in
{
  imports = [
    ./refind-theme.nix
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    bootloader = "refind";
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 50;

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

        # Diagnostics for the gnu-efi 4 hang. Select by hand; never the default.
        menuentry "TEST: rEFInd gnu-efi 4 (graphics)" {
            loader \EFI\refind\test-gfx\refind_x64.efi
        }

        menuentry "TEST: rEFInd gnu-efi 4 (textonly)" {
            loader \EFI\refind\test-txt\refind_x64.efi
        }
      '';

      extraFiles = inputs.lanzaboote.lib.fetchRefindTheme {
        inherit lib pkgs;

        owner = "catppuccin";
        repo = "refind";
        rev = "main";
        sha256 = "sha256-34+MkvWEp3xq6Di1uWKR4ieaG4t2rufnRRN1/V0WRfw=";
      }
      // {
        "test-gfx/refind_x64.efi" = "${refindGnuEfi4}/share/refind/refind_x64.efi";
        "test-gfx/refind.conf" = mkTestConf { textonly = false; };
        "test-txt/refind_x64.efi" = "${refindGnuEfi4}/share/refind/refind_x64.efi";
        "test-txt/refind.conf" = mkTestConf { textonly = true; };
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
