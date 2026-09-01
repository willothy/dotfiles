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

    # simpledrm inherits whatever GOP mode is set at handoff, and software
    # rendering there is pixel-bound. The EFI stub picks the mode before
    # ExitBootServices, so this only affects the kernel - rEFInd's menu stays
    # at the 3440x1440 it pins for itself. Same 21:9 aspect, 44% fewer pixels.
    "video=efifb:2560x1080"

    # nvidia
    "nvidia-drm.modeset=1"
    # "NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  # boot.kernel.sysctl."kernel.modules_disabled" = 0;

  # for dev on firecracker
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}
