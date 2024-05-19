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

  # mkfs.ext4 -L disk-00 -T largefile DEVICE
  fileSystems."/mnt/disks/00" = {
    device = "/dev/disk/by-id/ata-HUH721212ALE601_8DHEBDUH-part1";
    fsType = "ext4";
    options = [ "defaults" "nofail" "noatime" ];
  };

  # fileSystems."/mnt/disks/0" = {
  #   device = "/dev/sdb1";
  #   fsType = "ext4";
  #   options = [ "defaults" "noatime" ];
  # };

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

  ## Snapraid
  
  fileSystems."/mnt/parity/00" = {
    device = "/dev/disk/by-id/ata-HUH721212ALE601_8HKV7H3H-part1";
    # https://www.snapraid.it/faq#fs
    # mkfs.ext4 -m 0 -L DEVICE -T largefile4 DEVICE
    fsType = "ext4";
    options = ["defaults" "nofail" "noatime"];
  };

  snapraid = {
    enable = true;
    sync = {
      interval = "daily"; 
    };
    scrub = {
      interval = "weekly";
      olderThan = 10; # Number of days since data was last scrubbed before it can be scrubbed again.
      plan = 8; # Percentage to scrub
    };
    dataDisks = {
      d1 = "/mnt/disks/00";
    };
    contentFiles = [
      "/mnt/disks/00/.snapraid.content"
      "/var/snapraid/snapraid.content"
    ];
    parityFiles = [
      "/mnt/parity/00/snapraid.parity"
    ];
    exclude = [
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
      "/media/"
    ];
    extraConfig = ''
      autosave 500
    '';
  };

  # systemd.services.snapraid-sync = {
  #   serviceConfig = {
  #     RestrictNamespaces = lib.mkForce false;
  #     RestrictAddressFamilies = lib.mkForce "";
  #   };
  #   postStop = ''
  #   if [[ $SERVICE_RESULT =~ "success" ]]; then
  #     message=""
  #   else
  #     message=$(journalctl --unit=snapraid-sync.service -n 20 --no-pager)
  #   fi
  #   /run/current-system/sw/bin/notify -s "$SERVICE_RESULT" -t "Snapraid Sync" -m "$message"
  #   '';
  # };

  # systemd.services.snapraid-scrub = {
  #   serviceConfig = {
  #     RestrictAddressFamilies = lib.mkForce "";
  #   };
  #   postStop = ''
  #   if [[ $SERVICE_RESULT =~ "success" ]]; then
  #     message=""
  #   else
  #     message=$(journalctl --unit=snapraid-scrub.service -n 20 --no-pager)
  #   fi
  #   /run/current-system/sw/bin/notify -s "$SERVICE_RESULT" -t "Snapraid Scrub" -m "$message"
  #   '';
  # };

}
