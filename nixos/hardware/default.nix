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
  # Deliberately NOT loading nvidia in the initrd.
  #
  # It looks like the way to get an early splash, but it is the opposite. The
  # firmware hands over a GOP framebuffer and the kernel's built-in simpledrm
  # binds to it at ~0.99s, before plymouth starts at ~1.14s - so there is
  # already a DRM device to draw on. Pulling nvidia in costs ~97MB of GSP
  # firmware in the initrd (gsp_ga10x.bin 69MB + gsp_tu10x.bin 28MB, the
  # latter being Turing firmware this Blackwell card never uses) plus 1.7s of
  # nvidia-drm init, to provide a display 2s later than simpledrm already did.

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = false;
    open = true;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
}
