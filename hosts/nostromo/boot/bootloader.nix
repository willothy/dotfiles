{ config, lib, pkgs, inputs, ... }:
let
  version = "0.14.2";

  # rEFInd's official binary release, built by the project rather than by
  # nixpkgs.
  #
  # nixpkgs builds refind against gnu-efi 4, and that binary loads correctly
  # here - LoadImage succeeds - then hangs before its first console write,
  # before it even reads refind.conf. nixpkgs' older gnu-efi 3 build of the
  # same version works, and so does this one. All three were compared by
  # chainloading them from the working bootloader, which is also why this is a
  # binary release rather than a source build: it is the artifact that was
  # actually verified to boot on this machine.
  refindUpstream =
    let
      zip = pkgs.fetchurl {
        url = "https://downloads.sourceforge.net/project/refind/${version}/refind-bin-${version}.zip";
        hash = "sha256-QQx4KMT+wvIXm9lWBzUiQVgx0nwAQWOBuPcRU8GQoxE=";
      };
    in
    pkgs.runCommand "refind-bin-${version}" { nativeBuildInputs = [ pkgs.unzip ]; } ''
      unzip -j ${zip} 'refind-bin-${version}/refind/refind_x64.efi' -d .
      install -Dm444 refind_x64.efi $out/share/refind/refind_x64.efi
    '';
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
      package = refindUpstream;

      extraConfig = ''
        # Pin the GOP mode to the panel's native resolution. The kernel
        # inherits this framebuffer, so simpledrm comes up correctly
        # proportioned instead of at whatever fallback the firmware picked.
        resolution 3440 1440

        hideui singleuser,hints,arrows,badges,safemode,hwtest

        use_graphics_for osx,linux,elilo,grub,windows

        icons_dir themes/refind/assets/mocha/icons

        banner themes/refind/assets/mocha/background.png

        banner_scale fillscreen

        selection_big   themes/refind/assets/mocha/selection_big.png
        selection_small themes/refind/assets/mocha/selection_small.png

        scanfor internal,external,manual
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
    consoleMode = "max";
    windows = {
      win11 = {
        sortKey = "0"; # alway first
        title = "Windows 11";
        efiDeviceHandle = "HD3b";
      };
    };
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
    extraConfig = ''
      resolution 0

      hideui singleuser,hints,arrows,badges,safemode,hwtest

      use_graphics_for osx,linux,elilo,grub,windows

      icons_dir themes/catppuccin/assets/mocha/icons

      banner themes/catppuccin/assets/mocha/background.png

      banner_scale fillscreen

      selection_big   themes/catppuccin/assets/mocha/selection_big.png
      selection_small themes/catppuccin/assets/mocha/selection_small.png

      dont_scan_dirs EFI/nixos, EFI/ubuntu, EFI/systemd, EFI/BOOT
    '';
  };
}
