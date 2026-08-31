{ config, pkgs, ... }:
{
  hardware.cpu.amd.updateMicrocode = true;
  hardware.i2c.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [

    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = false;
    open = true;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
}
