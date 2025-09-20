{ config, pkgs, ... }:
{
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.systemd-boot = {
    enable = true;
    consoleMode = "max";
    windows = {
      win11 = {
        title = "Windows 11";
        efiDeviceHandle = "HD4b";
      };
    };

    # Used to get the efiDeviceHandle
    # edk2-uefi-shell.enable = true;
  };
}
