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
  # boot.initrd.kernelModules = [
  #   "nvidia"
  #   "nvidia_modeset"
  #   "nvidia_drm"
  # ];

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = false;
    open = true;

    nvidiaSettings = true;

    # gsp_tu10x.bin is Turing firmware; this card uses the ga10x lineage. It is
    # 28MB of the ~111MB initrd, read by the firmware on every boot.
    package = config.boot.kernelPackages.nvidiaPackages.beta.overrideAttrs (old: {
      # generic.nix defaults postInstall to null, not "".
      postInstall = (if old.postInstall == null then "" else old.postInstall) + ''
        rm -f "$firmware"/lib/firmware/nvidia/*/gsp_tu10x.bin
      '';
    });
  };
}
