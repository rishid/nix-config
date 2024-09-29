{ config, pkgs, ... }:

{
  imports = [
    ./paths.nix
    ./hardware-configuration.nix
    ./mounts.nix
    ./disko-config.nix    
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true; 
  boot.loader.efi.canTouchEfiVariables = true;

  # Use freshest kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  # Memory management
  modules.earlyoom.enable = true;

  services.fstrim.enable = true;

  powerManagement.powertop.enable = true;

  programs.nix-ld.enable = true;
  modules.samba = {
    enable = true;
    # shares = {
    #   Backup = {
    #       path = "/tank/Backup";
    #       "read only" = "no";
    #     };
    #   Docs = {
    #     path = "/tank/Docs";
    #     "read only" = "no";
    #   };
    #   Media = {
    #     path = "/tank/Media";
    #     "read only" = "no";
    #   };
    #   Paperless = {
    #     path = "/tank/Apps/paperless/incoming";
    #     "read only" = "no";
    #   };
    #   Software = {
    #     path = "/tank/Software";
    #     "read only" = "no";
    #   };
    #   TimeMachineBackup = {
    #     "vfs objects" = "acl_xattr catia fruit streams_xattr";
    #     "fruit:time machine" = "yes";
    #     "comment" = "Time Machine Backups";
    #     "path" = "/tank/Backup/TimeMachine";
    #     "read only" = "no";
    #   };
    # };
  };

  # modules.restic = {
  #   enable = true;
  #   repositoryPath = "/restic";
  #   passwordFile = config.age.secrets.restic-password.path;
  #   # timerConfig = {
  #   #   OnCalendar = "02:00";
  #   #   RandomizedDelaySec = "1h";
  #   # };

  #   prune = {
  #     options = [
  #       "--keep-daily 7"
  #       "--keep-weekly 5"
  #       "--keep-monthly 12"
  #       "--keep-yearly 75"
  #     ];
  #     timerConfig = {
  #       OnCalendar = "07:00";
  #       RandomizedDelaySec = "2h";
  #     };
  #   };
  # };

  backup = {
    localEnable = true;
    passwordFile = config.age.secrets.restic-password.path;
    localRepositoryPath = "/root/restic-bk";
    backup-paths-exclude = [
      "*.pyc"
      "*/.cache"
      "*/.cargo"
      "*/.container-diff"
      "*/.go/pkg"
      "*/.gvfs/"
      "*/.local/share/Steam"
      "*/.local/share/Trash"
      "*/.local/share/virtualenv"
      "*/.mozilla/firefox"
      "*/.rustup"
      "*/.vim"
      "*/.vimtemp"
    ];
    # backup-paths-offsite = [ config.services.postgresqlBackup.location ];
  };
   

  # # Backup Postgres, if it is running
  # services.postgresqlBackup = {
  #   enable = config.services.postgresql.enable;
  #   startAt = "*-*-* 01:15:00";
  #   location = "/var/backup/postgresql";
  #   backupAll = true;
  # };

  networking.extraHosts = ''
    192.168.1.1   router.home
  '';

  # Network
  modules.tailscale.enable = true;
  modules.ddns.enable = true;
  modules.sftp-server.enable = true;

  # Security
  modules.vaultwarden = {
    enable = true;
    hostName = "pass.${config.networking.domain}";
  };
  modules.authelia.enable = true;

  modules.homepage.enable = true;
  modules.whoami.enable = true;
  modules.smartd.enable = true;
  
  # Media management
  # modules.plex.enable = true;
  modules.jellyfin.enable = true;
  modules.immich = {
    enable = true;
    photosDir = "/mnt/pool/photos/immich";
    externalDir = "/mnt/pool/photos/Years";
  };

  # Content getters
  modules.bazarr.enable = true;  
  # modules.overseerr = {
  #   enable = true;
  #   hostName = "requests.${config.networking.domain}";
  # };
  modules.jellyseerr = {
    enable = true;
    hostName = "requests.${config.networking.domain}";
  };
  modules.prowlarr.enable = true;
  modules.radarr.enable = true;
  modules.sonarr.enable = true;
  # modules.transmission-ovpn.enable = true;    
  modules.qbittorrent.enable = true;
  modules.unpackerr.enable = true;

  # Utils
  modules.filebrowser = {
    enable = true;
    hostName = "files.${config.networking.domain}";
  };
  
  # TODO:
  # usb backup
  # camera auto download
  # need to write or find a script that will run on udev USB plugin and grab
  # all DSLR camera files


  # modules.tautulli.enable = true;
  # modules.silverbullet.enable = true;
  # modules.tandoor-recipes.enable = false; 
  # modules.lunasea.enable = true;
  # modules.sabnzbd.enable = true;
  # modules.ombi.enable = true;

  # modules.nextcloud.enable = false;
  # modules.ocis.enable = true;
  # modules.gitea.enable = true;
  # modules.tiddlywiki.enable = true;
  # modules.wallabag.enable = false;

  # modules.freshrss.enable = true;
 
  # modules.cockpit.enable = true;

  # modules.auto-index = {
  #   enable = true;
  #   indexDir = "/data";
  #   hostname = "index";
  # }

  # modules.photoprism = {
  #   enable = false;
  #   photosDir = "/data/photos";
  # };
  
  programs.ssh.startAgent = true;

  # services.tailscale.extraUpFlags = ["--ssh" ];

  #nixpkgs.config.packageOverrides = pkgs: {
  #  vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  #};
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime
    ];
  };

  # services.hddfancontrol = {
  #   enable = true;
  #   disks = [
  #     "/dev/disk/by-partlabel/disk0"
  #     "/dev/disk/by-partlabel/disk1"
  #     # "/dev/disk/by-label/Parity1"
  #   ];
  #   pwmPaths = [
  #     "/sys/class/hwmon/hwmon0/pwm2"
  #   ];
  #   extraArgs = [
  #     "--pwm-start-value=100"
  #     "--pwm-stop-value=50"
  #     "--smartctl"
  #     "--min-fan-speed-prct 10"
  #     "-i 30"
  #     "--spin-down-time=1800"
  #   ];
  # };

  # systemd.services.hd-idle = {
  #   description = "HD spin down daemon";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.hd-idle}/bin/hd-idle -i 900";
  #   };
  # };
  
  # # List packages installed in system profile. To search, run:
  # # $ nix search wget
  environment.systemPackages = with pkgs; [
    age
    bc
    jellyfin-ffmpeg
    exiftool
    fio
    iftop
    httpie
    intel-gpu-tools
    lm_sensors
    ncdu
    nfs-utils
    quickemu
    parted
    patchelf    
    powertop
    python3
    rclone    
    speedtest-cli
    stdenv    
    stdenv.cc
    tcpdump
  ];

  systemd = {
    services.clear-log = {
      description = "Clear >2 month-old logs every week";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=60d";
      };
    };
    timers.clear-log = {
      wantedBy = [ "timers.target" ];
      partOf = [ "clear-log.service" ];
      timerConfig.OnCalendar = "weekly UTC";
    };

    # Turn off power at night if I forget. Remove once running 24x7
    services.sched-shutdown = {
      description = "Scheduled shutdown";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.systemd}/bin/systemctl --force poweroff";
      };
    };
    timers.sched-shutdown = {
      wantedBy = [ "timers.target" ];
      partOf = [ "sched-shutdown.service" ];
      timerConfig.OnCalendar = "*-*-* 22:00:00";
    };
 
    # force enable ASPM. Newer kernels do not enable by default.
    services.realtek-aspm = {
      # enable =
      #   lib.versionAtLeast config.boot.kernelPackages.kernel.version "5.5";
      description =
        "Enable power-saving states for Realtek NIC";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      # the device ID and states that need to be enabled may change per device
      script = ''
        echo 1 | tee /sys/bus/pci/drivers/r8169/0000\:02\:00.0/link/l1_2_aspm
      '';
    };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  # system.stateVersion = "23.11"; # Did you read the comment?

}
