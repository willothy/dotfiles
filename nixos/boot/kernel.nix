{ config, pkgs, ... }:
{
  # issue with 6.18 and nvidia drivers
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.kernelParams = [
    "quiet"
    "splash"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"

    # nvidia
    "nvidia-drm.modeset=1"
    # "NVreg_PreserveVideoMemoryAllocations=1"

    # TEMPORARY: why does plymouth draw nothing on simpledrm?
    # Plain plymouth.debug redirects to /dev/tty1, which the journal misses.
    "plymouth.debug=stream:/dev/kmsg"
  ];

  # boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  # boot.kernel.sysctl."kernel.modules_disabled" = 0;

  # for dev on firecracker
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}
