{ config, pkgs, ... }:
{
  # linuxPackages_latest (6.18) had issues with the nvidia drivers
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.kernelParams = [
    "quiet"
    "splash"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"

    # nvidia
    "nvidia-drm.modeset=1"
  ];

  # for dev on firecracker
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}
