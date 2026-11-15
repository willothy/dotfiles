{ config, pkgs, ... }:
{
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

  # Turn a hard hang into a logged panic and a reboot: the panic's log goes to
  # EFI pstore, and systemd-pstore copies it to /var/lib/systemd/pstore on the
  # next boot. hung_task_panic stays off, since long I/O waits under load
  # would trip it without anything being stuck.
  boot.kernel.sysctl = {
    "kernel.softlockup_panic" = 1;
    "kernel.hardlockup_panic" = 1;
    "kernel.panic" = 10;
    "kernel.sysrq" = 1;
  };
  boot.kernelModules = [ "efi_pstore" ];
  systemd.services.systemd-pstore.wantedBy = [ "sysinit.target" ];
}
