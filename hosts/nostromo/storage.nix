# Disks besides root (990 PRO) and /boot:
# - `fast`: the 980 (NVMe), one btrfs filesystem whose subvolumes share its
#   space: general data, and the `@microvms` and `@sccache` subvolumes the
#   CI runners that used to run here left behind, no longer mounted.
# - `bulk`: the 512 GB SATA SSD, for anything that doesn't need to be fast.
{ ... }:
let
  fast = "/dev/disk/by-uuid/ccd49911-df48-4c8f-8d94-3ddd88df16d8";
  bulk = "/dev/disk/by-uuid/53526ef2-177a-45cd-af38-0f3defc7cdb7";
in
{
  fileSystems = {
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
}
