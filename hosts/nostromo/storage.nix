# Disks besides root (990 PRO) and /boot:
# - `fast`: the 980 (NVMe), one btrfs filesystem whose subvolumes share its
#   space: the CI runners' VM images and compiler cache, and general data.
# - `bulk`: the 512 GB SATA SSD, for anything that doesn't need to be fast.
{ config, ... }:
let
  fast = "/dev/disk/by-uuid/ccd49911-df48-4c8f-8d94-3ddd88df16d8";
  bulk = "/dev/disk/by-uuid/53526ef2-177a-45cd-af38-0f3defc7cdb7";

  ciDirs = [
    config.services.crucible-ci-runner-vms.stateDirectory
    "/var/lib/crucible-ci-sccache"
  ];
in
{
  fileSystems = {
    ${config.services.crucible-ci-runner-vms.stateDirectory} = {
      device = fast;
      fsType = "btrfs";
      options = [ "subvol=@microvms" "noatime" ];
    };

    "/var/lib/crucible-ci-sccache" = {
      device = fast;
      fsType = "btrfs";
      options = [ "subvol=@sccache" "noatime" ];
    };

    # Plain storage: a missing disk shouldn't stop the desktop from booting.
    "/mnt/fast" = {
      device = fast;
      fsType = "btrfs";
      options = [ "subvol=@data" "noatime" "compress=zstd" "nofail" ];
    };

    "/mnt/bulk" = {
      device = bulk;
      fsType = "btrfs";
      options = [ "subvol=@data" "noatime" "compress=zstd" "nofail" ];
    };
  };

  # The VM images and the compiler cache's image are rewritten in place; on
  # btrfs, copy-on-write would fragment them. New files inherit +C.
  systemd.tmpfiles.rules = map (d: "h ${d} - - - - +C") ciDirs;
}
