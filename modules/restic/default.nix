# modules.restic.enable = true;
{ config, lib, pkgs, this, ... }:

let
  cfg = config.modules.restic;
  cfgB = config.backup;

  opTimeConfig = {
    OnCalendar = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = ''
        When to run the operation. See man systemd.timer for details.
      '';
    };
    RandomizedDelaySec = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        Delay the operation by a randomly selected, evenly distributed
        amount of time between 0 and the specified time value.
      '';
      example = "5h";
    };
  };

  inherit (config.networking) hostName;
  inherit (lib) mkEnableOption mkBefore mkOption options types mkIf optionalAttrs;
  inherit (lib.strings) optionalString;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;
in {
  imports = [
    ./fs.nix
  ];

  options.modules.restic = {
    enable = options.mkEnableOption "restic"; 
    hostName = mkOption {
      type = types.str; 
      default = "restic.${config.networking.domain}";
      description = "FQDN for the restic instance";
    };
    repositoryPath = mkOption {
      type = types.str;
      default = "./restic";
      description = "Path to the restic repository";
    };
    passwordFile = mkOption {
      type = types.path;
      description = "Read the repository password from a file.";
      example = "config.age.secrets.resticPassword.path";
    };
    ntfyPathFile = mkOption {
      type = types.str;
      description = "Read the ntfy.sh url path from a file";
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
    prune = {
      options = lib.mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          A list of options (--keep-* et al.) for 'restic forget
          --prune', to automatically prune old snapshots.
        '';
        example = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 75"
        ];
      };
      timerConfig = opTimeConfig;
    };
  };

  config = mkIf cfg.enable (let
    resticName = "systemBackup";
    pruneName = "restic-backups-prune";
    systemdServiceName = "restic-backups-${resticName}";

    mkNtfyScript = status: priority: tag: ''
      ${lib.getExe pkgs.curl} -u :$(cat $NTFY_TOKEN) \
        -H "Title: Restic Backup" \
        -H "Priority: ${priority}" \
        -H "Tags: floppy_disk,${tag}" \
        -H "Icon: https://avatars.githubusercontent.com/u/10073512?s=200&v=4" \
        -d "Backup ${hostName} ${status}." \
        https://ntfy.snakepi.xyz/dev
    '';
  in {
    # sops.secrets = {
    #   "restic/rclone".sopsFile = ./secrets.yaml;
    #   "restic/password".sopsFile = ./secrets.yaml;
    #   "restic/ntfy".sopsFile = ./secrets.yaml;
    # };

    # lib.backup.repository = "${cfg.repository}";
    # lib.backup.extraOptions = [
    #   "sftp.command='${sftpCommand}'"
    # ];
    lib.backup.timerConfig =
      {
        OnCalendar = cfg.timerConfig.OnCalendar;
      }
      // lib.optionalAttrs (cfg.timerConfig.RandomizedDelaySec != null) {
        RandomizedDelaySec = cfg.timerConfig.RandomizedDelaySec;
      };

    systemd.services."${pruneName}" = let
      extraOptions = lib.concatMapStrings (arg: " -o ${arg}") config.lib.backup.extraOptions;
      resticCmd = "${pkgs.restic}/bin/restic${extraOptions}";
    in
      lib.mkIf (builtins.length cfg.prune.options > 0) {
        environment = {
          RESTIC_PASSWORD_FILE = cfg.passwordFile;
          RESTIC_REPOSITORY = config.lib.backup.repository;
        };
        path = [pkgs.openssh];
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = [
            (resticCmd + " forget --prune " + (lib.concatStringsSep " " cfg.prune.options))
            (resticCmd + " check")
          ];
          # ExecStartPost = "${checkRepoSpace}/bin/check-repo-space";
          User = "root";
          RuntimeDirectory = pruneName;
          CacheDirectory = pruneName;
          CacheDirectoryMode = "0700";
        };
      };
    systemd.timers."${pruneName}" = lib.mkIf (builtins.length cfg.prune.options > 0) {
      wantedBy = ["timers.target"];
      timerConfig = cfg.prune.timerConfig;
    };
  });
}

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
