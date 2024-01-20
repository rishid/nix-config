# modules.restic.enable = true;
{ config, lib, pkgs, this, ... }:

let
  # cfg = config.modules.restic;
  cfg = config.backup;

  # opTimeConfig = {
  #   OnCalendar = lib.mkOption {
  #     type = lib.types.str;
  #     default = "daily";
  #     description = ''
  #       When to run the operation. See man systemd.timer for details.
  #     '';
  #   };
  #   RandomizedDelaySec = lib.mkOption {
  #     type = with lib.types; nullOr str;
  #     default = null;
  #     description = ''
  #       Delay the operation by a randomly selected, evenly distributed
  #       amount of time between 0 and the specified time value.
  #     '';
  #     example = "5h";
  #   };
  # };

  inherit (lib) mkEnableOption mkBefore mkOption options types mkIf optionalAttrs;
  
in {
  
  options.backup = {
    localEnable = mkEnableOption "local restic backups";
    remoteEnable = mkEnableOption "remote restic backups";
    
    passwordFile = mkOption {
      type = types.path;
      description = "Read the repository password from a file.";
      example = "config.age.secrets.restic-password.path";
    };

    ntfyPathFile = mkOption {
      type = types.str;
      description = "Read the ntfy.sh url path from a file";
    };

    localRepositoryPath = mkOption {
      type = types.str;
      default = "./restic";
      description = "Path to the local restic repository";
    };

    localPaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/home/pinpox/Notes" ];
      description = "Paths to backup to onsite storage";
    };

    backup-paths-offsite = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/home/pinpox/Notes" ];
      description = "Paths to backup to offsite storage";
    };

    backup-paths-exclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/home/pinpox/cache" ];
      description = "Paths to exclude from backup";
    };
  };  
    # timerConfig = opTimeConfig;

    # timerConfig = mkOption {
    #   type = types.attrsOf unitOption;
    #   default = { OnCalendar = "daily"; };
    #   description = lib.mdDoc "When to run the backup. See man systemd.timer for details.";
    #   example = {
    #     OnCalendar = "00:05";
    #     RandomizedDelaySec = "5h";
    #   };
    # };

  config = mkIf cfg.localEnable (let
    resticName = "systemBackup";
    pruneName = "restic-backups-prune";
    systemdServiceName = "restic-backups-${resticName}";

    mkNtfyScript = status: priority: tag: ''
      ${lib.getExe pkgs.curl} -u :$(cat $NTFY_TOKEN) \
        -H "Title: Restic Backup" \
        -H "Priority: ${priority}" \
        -H "Tags: floppy_disk,${tag}" \
        -H "Icon: https://avatars.githubusercontent.com/u/10073512?s=200&v=4" \
        -d "Backup ${config.networking.hostName} ${status}." \
        https://ntfy.snakepi.xyz/dev
    '';

    # script-post = host: site: ''
    #   if [ $EXIT_STATUS -ne 0 ]; then
    #     ${lib.getExe pkgs.curl} -u $NTFY_USER:$NTFY_PASS \
    #     -H 'Title: Backup (${site}) on ${host} failed!' \
    #     -H 'Tags: backup,borg,${host},${site}' \
    #     -d "Restic (${site}) backup error on ${host}!" 'https://push.pablo.tools/pinpox_backups'
    #   else
    #     ${lib.getExe pkgs.curl} -u $NTFY_USER:$NTFY_PASS \
    #     -H 'Title: Backup (${site}) on ${host} successful!' \
    #     -H 'Tags: backup,borg,${host},${site}' \
    #     -d "Restic (${site}) backup success on ${host}!" 'https://push.pablo.tools/pinpox_backups'
    #   fi
    # '';
    script-post = host: site: ''
      if [ $EXIT_STATUS -ne 0 ]; then
        ${lib.getExe pkgs.curl} \
        -H 'Priority: urgent' \
        -H 'Title: Backup (${site}) on ${host} failed!' \
        -H 'Tags: floppy_disk,backup,${host},${site}' \
        -d "Restic (${site}) backup error on ${host}!" \
        ntfy.sh/downtherabbithole
      else
        ${lib.getExe pkgs.curl} \
        -H 'Priority: default' \
        -H 'Title: Backup (${site}) on ${host} successful!' \
        -H 'Tags: floppy_disk,backup,${host},${site}' \
        -d "Restic (${site}) backup success on ${host}!" \
        ntfy.sh/downtherabbithole
      fi
    '';

    restic-ignore-file = pkgs.writeTextFile {
      name = "restic-ignore-file";
      text = builtins.concatStringsSep "\n" cfg.backup-paths-exclude;
    };

  in {
    # lib.backup.repository = "${cfg.repository}";
    # lib.backup.extraOptions = [
    #   "sftp.command='${sftpCommand}'"
    # ];
    # lib.backup.timerConfig =
    #   {
    #     OnCalendar = cfg.timerConfig.OnCalendar;
    #   }
    #   // lib.optionalAttrs (cfg.timerConfig.RandomizedDelaySec != null) {
    #     RandomizedDelaySec = cfg.timerConfig.RandomizedDelaySec;
    #   };

    services.restic.backups = 
      let
        restic-ignore-file = pkgs.writeTextFile {
          name = "restic-ignore-file";
          text = builtins.concatStringsSep "\n" cfg.backup-paths-exclude;
        };
      in
      {
        local = {          
          repository = cfg.localRepositoryPath;
          passwordFile = cfg.passwordFile;
          initialize = true;
          createWrapper = true;

          paths = cfg.localPaths;

          # timerConfig = {
          #   OnCalendar = "00:05";
          #   RandomizedDelaySec = "5h";
          # };
          
          # environmentFile = "${config.lollypops.secrets.files."restic/backblaze-credentials".path}";          
          backupCleanupCommand = script-post config.networking.hostName "local";

          extraBackupArgs = [
            "--exclude-file=${restic-ignore-file}"
            "--one-file-system"
            # "--dry-run"
            "-vv"
          ];
        };
      };
  });
}

#     systemd.services."${pruneName}" = let
#       # extraOptions = lib.concatMapStrings (arg: " -o ${arg}") config.lib.backup.extraOptions;
#       # resticCmd = "${pkgs.restic}/bin/restic${extraOptions}";
#       resticCmd = "${pkgs.restic}/bin/restic";
#     in
#       lib.mkIf (builtins.length cfg.prune.options > 0) {
#         environment = {
#           RESTIC_PASSWORD_FILE = cfg.passwordFile;
#           RESTIC_REPOSITORY = cfg.repositoryPath;
#         };
#         # path = [pkgs.openssh];
#         restartIfChanged = false;
#         serviceConfig = {
#           Type = "oneshot";
#           ExecStart = [
#             (resticCmd + " forget --prune " + (lib.concatStringsSep " " cfg.prune.options))
#             (resticCmd + " check")
#           ];
#           # ExecStartPost = "${checkRepoSpace}/bin/check-repo-space";
#           User = "root";
#           RuntimeDirectory = pruneName;
#           CacheDirectory = pruneName;
#           CacheDirectoryMode = "0700";
#         };
#       };
#     systemd.timers."${pruneName}" = lib.mkIf (builtins.length cfg.prune.options > 0) {
#       wantedBy = ["timers.target"];
#       timerConfig = cfg.prune.timerConfig;
#     };
#   });
# }

#     services.restic.backups.persist = {
#       repository = "/media/External/backups/system";
#       # repository = "rclone:onedrive:Backups/persist/${hostName}";
#       passwordFile = cfg.passwordFile;

#       initialize = true;

#       paths = cfg.paths;
#       exclude = cfg.exclude;
#       extraBackupArgs = [ "--exclude-caches" ];
      
#       pruneOpts = [
#         "--keep-last 20"
#         "--keep-daily 7"
#         "--keep-weekly 4"
#         "--keep-monthly 6"
#         "--keep-yearly 3"
#       ];
#       timerConfig = {
#         OnCalendar = "daily";
#         Persistent = true;
#         RandomizedDelaySec = "1h";
#       };
      
#       backupPrepareCommand = mkNtfyScript "start" "default" "yellow_circle";
#     };

#     systemd.services = {
#       restic-backups-persist = {
#         onSuccess = [ "restic-ntfy-success.service" ];
#         onFailure = [ "restic-ntfy-failure.service" ];
#       };

#       restic-ntfy-success = {
#         environment.NTFY_TOKEN = config.sops.secrets."restic/ntfy".path;
#         script = mkNtfyScript "success" "default" "green_circle";
#       };

#       restic-ntfy-failure = {
#         environment.NTFY_TOKEN = config.sops.secrets."restic/ntfy".path;
#         script = mkNtfyScript "failure" "high" "red_circle";
#       };
#     };

#     systemd.services =
#       lib.mapAttrs'
#       (
#         name: backup:
#           lib.nameValuePair "restic-backups-fs-${name}" {
#             path = [pkgs.gawk pkgs.gnugrep];
#             serviceConfig.ExecStartPost = "${exporter}/bin/restic-exporter %n";
#           }
#       )
#       cfg.fsBackups;
      
#   });
# }
