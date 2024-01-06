{
  disko.devices = {
    disk = {
      vdb = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5P2NU0W402220Y";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
    nodev = {
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=2000M"
        ];
      };
    };
  };
}
