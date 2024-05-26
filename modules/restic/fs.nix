{ config, lib, pkgs, this, ... }: let
  cfg = config.modules.restic;
  cfgB = config.backup;

  inherit (lib) mkIf;
in {
  options.backup.fsBackups = lib.mkOption {
    description = ''
      Periodic backups of the filesystem.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          paths = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "Which paths to backup. If null or an empty array, no backup
              command will be run. This can be used to create a prune-only job.";
            example = [ "/var/lib/postgresql" "/home/user/backup" ];
          };

          excludes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Patterns to exclude when backing up.";
            example =
              [
                "**/node_modules/"
                "**/.DS_Store"
                "**/.stfolder"
              ];
            default = [ "**/.DS_Store" "**/.direnv" ];
          };
        };
      }
    );
    default = {};
    example = {
      home = {
        paths = ["/home"];
      };
      music = {
        paths = ["/pool/music"];
      };
    };
  };

  config = mkIf cfg.enable (let
    exporter = pkgs.writeShellScriptBin "restic-exporter" (builtins.readFile ./restic-exporter.sh);
  in {
    services.restic.backups =
      lib.mapAttrs'
      (
        name: backup:
          lib.nameValuePair "fs-${name}" {
            repository = cfg.repositoryPath;
            passwordFile = cfg.passwordFile;
            initialize = true;
            # extraOptions = config.lib.backup.extraOptions;
            extraBackupArgs = ["--exclude-caches"];
            paths = backup.paths;
            exclude = backup.excludes;
            # timerConfig = "daily";
            timerConfig = config.lib.backup.timerConfig;
          }
      )
      cfgB.fsBackups;

    # update backup systemd services to add notify scripts
    systemd.services =
      lib.mapAttrs'
      (
        name: backup:
          lib.nameValuePair "restic-backups-fs-${name}" {
            onSuccess = [ "restic-ntfy-success.service" ];
            onFailure = [ "restic-ntfy-failure.service" ];
            # path = [pkgs.gawk pkgs.gnugrep];
            # serviceConfig.ExecStartPost = "${exporter}/bin/restic-exporter %n";
          }
      )
      cfgB.fsBackups;
  });
}
