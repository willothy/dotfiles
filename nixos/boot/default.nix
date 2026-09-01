{ config, pkgs, ... }:
let
  # The stock spinner theme, repainted in catppuccin mocha to match rEFInd.
  # Only the colours change; the animation frames are the originals.
  spinnerCatppuccin =
    pkgs.runCommand "plymouth-theme-spinner-catppuccin"
      {
        nativeBuildInputs = [ pkgs.buildPackages.coreutils ];
      }
      ''
        dir=$out/share/plymouth/themes/spinner-catppuccin
        mkdir -p "$dir"
        cp ${pkgs.plymouth}/share/plymouth/themes/spinner/* "$dir"/
        mv "$dir"/spinner.plymouth "$dir"/spinner-catppuccin.plymouth

        substituteInPlace "$dir"/spinner-catppuccin.plymouth \
          --replace-fail \
            'ImageDir=${pkgs.plymouth}/share/plymouth/themes//spinner' \
            "ImageDir=$dir" \
          --replace-fail 'BackgroundStartColor=0x000000' 'BackgroundStartColor=0x1e1e2e' \
          --replace-fail 'BackgroundEndColor=0x000000' 'BackgroundEndColor=0x1e1e2e' \
          --replace-fail 'ProgressBarBackgroundColor=0x606060' 'ProgressBarBackgroundColor=0x313244' \
          --replace-fail 'ProgressBarForegroundColor=0xffffff' 'ProgressBarForegroundColor=0xcba6f7'
      '';
in
{
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
    theme = "spinner-catppuccin";
    themePackages = [ spinnerCatppuccin ];
  };
}
