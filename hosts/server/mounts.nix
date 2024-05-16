{ lib, ... }:

{
  environment.systemPackages = with pkgs; [
    gptfdisk
    xfsprogs
    parted
    snapraid
    mergerfs
    mergerfs-tools
  ];

  fileSystems."/mnt/storage/disk1" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [ "defaults" "largefile" ];
  };

  fileSystems."/mnt/storage/disk2" = {
    device = "/dev/sdb1";
    fsType = "ext4";
    options = [ "defaults" "largefile" ];
  };

  fileSystems."/mnt/storage" = {
    device = "/mnt/disks/*";
    fsType = "fuse.mergerfs";
    options = [ "defaults" "allow_other" "category.create=mfs" "moveonenospc=true" "minfreespace=5G" ];
  };

  # fileSystems."/storage" = {
  #   fsType = "fuse.mergerfs";
  #   device = "/mnt/disks/*";
  #   options = ["cache.files=partial" "dropcacheonclose=true" "category.create=mfs"];
  # };
}
