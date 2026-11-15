{
  disko.devices.disk.hdd = {
    type = "disk";
    device = "/dev/disk/by-id/ata-ST1000DM003-1ER162_Z4Y82QQH";
    content = {
      type = "gpt";
      partitions.data = {
        size = "100%";
        content = {
          type = "btrfs";
          extraArgs = [ "-f" ];
          mountpoint = "/mnt/hdd";
          mountOptions = [
            "noauto"
            "nofail"
            "x-systemd.automount"
            "x-systemd.idle-timeout=10min"
            "compress=zstd"
            "noatime"
          ];
        };
      };
    };
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-Samsung_SSD_990_1TB_S818NT0L820137T";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
