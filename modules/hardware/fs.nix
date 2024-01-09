{ config, options, lib, pkgs, ... }:

with lib;
# with lib.my;
let cfg = config.modules.hardware.fs;
in {
  options.modules.hardware.fs = {
    enable = mkEnableOption "Enable file system features";
    zfs.enable = mkEnableOption "Enable zfs features";
    ssd.enable = mkEnableOption "Enable SSD features";
    # TODO automount.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.udevil.enable = true;

      # Support for more filesystems, mostly to support external drives
      environment.systemPackages = with pkgs; [
        sshfs
        exfat     # Windows drives
        ntfs3g    # Windows drives
        hfsprogs  # MacOS drives
      ];
    }

    (mkIf (!cfg.zfs.enable && cfg.ssd.enable) {
      services.fstrim.enable = true;
    })

    (mkIf cfg.zfs.enable (mkMerge [
      {
        boot.loader.grub.copyKernels = true;
        boot.supportedFilesystems = [ "zfs" ];
        boot.zfs.devNodes = "/dev/disk/by-partuuid";
        services.zfs.autoScrub.enable = true;
      }

      (mkIf cfg.ssd.enable {
        # Will only TRIM SSDs; skips over HDDs
        services.fstrim.enable = false;
        # services.zfs.trim.enable = true;
      })
    ]))
  ]);
}
