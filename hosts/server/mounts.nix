{ config, pkgs, ... }:

{
  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
    gptfdisk
    parted
    snapraid
    mergerfs
    mergerfs-tools
  ];

  fileSystems."/mnt/disks/disk1" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  fileSystems."/mnt/disks/disk2" = {
    device = "/dev/sdb1";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  fileSystems.${config.paths.storage} = {
    device = "/mnt/disks/*";
    fsType = "fuse.mergerfs";
    options = [ 
        "defaults"
        # partial cache required for mmap support for qbittorrent
        # ref: https://github.com/trapexit/mergerfs#you-need-mmap-used-by-rtorrent-and-many-sqlite3-base-software
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=mfs"
        "minfreespace=5G" 
      ];
  };

  # fileSystems."/mnt/parity1" = {
  #     device = "/dev/disk/by-id/usb-WDC_WD40_EFPX-68C6CN0_152D00539000-0:0-part1";
  #     # https://www.snapraid.it/faq#fs
  #     # mkfs.ext4 -m 0 -T largefile4 DEVICE
  #     fsType = "ext4";
  #     options = ["defaults" "noatime"];
  #   };
}
