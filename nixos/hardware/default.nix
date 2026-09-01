{ config, pkgs, ... }:
{
  hardware.cpu.amd.updateMicrocode = true;
  hardware.i2c.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [

    ];
  };

  # The primary display hangs off the NVIDIA card (card1), so without these in
  # the initrd there is no DRM device during early boot: plymouth starts, finds
  # nothing to draw on, and exits having shown no splash. nixpkgs 26.11 also
  # moved nvidia-drm.fbdev/modeset from the kernel command line into
  # modprobe.d, which only applies once the module is loaded - so it has to be
  # loaded early to matter.
  # Only what KMS needs. nvidia_uvm is CUDA/compute and is not required to put
  # a picture on screen, so it stays out of the initrd - nvidia.ko alone
  # expands to roughly 90MB there, and every megabyte is read off the ESP by
  # the firmware before the kernel starts.
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
