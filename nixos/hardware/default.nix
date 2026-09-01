{ config, pkgs, ... }:
{
  hardware.cpu.amd.updateMicrocode = true;
  hardware.i2c.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [

    ];
  };

  # Plymouth needs a DRM device in the initrd; simpledrm was tried and doesn't
  # work here. Costs ~95MB of GSP firmware in the initrd and ~1.7s of
  # nvidia-drm init, which is the blank screen before the splash.
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_drm"
  ];

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = false;
    open = true;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
}
