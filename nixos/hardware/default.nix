{ config, pkgs, ... }:
{
  hardware.cpu.amd.updateMicrocode = true;
  hardware.i2c.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = true;
    open = true;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
}
