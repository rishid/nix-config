# modules.unpackerr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "golift/unpackerr";
  version = "latest";

  cfg = config.modules.unpackerr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.unpackerr = {
    enable = options.mkEnableOption "unpackerr";
  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.unpackerr = lib.mkForce 923;
    ids.gids.unpackerr = lib.mkForce 923;

    users = {
      users = {

        unpackerr = {
          isSystemUser = true;
          group = "unpackerr";
          description = "unpackerr daemon user";          
          uid = config.ids.uids.unpackerr;
        };

      # Add admins to the unpackerr group
      } // extraGroups this.admins [ "unpackerr" ];

      # Create group
      groups.unpackerr = {
        gid = config.ids.gids.unpackerr;
      };

      groups.media.members = [ "unpackerr" ];

    };

    # backup.localPaths = [
    #   "${cfg.configDir}"
    # ];

    # NixOS unpackerr version is v3
    virtualisation.oci-containers.containers.unpackerr = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.unpackerr}:${toString config.ids.gids.unpackerr}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        # ${TDOWNLOADS}:/data/downloads
        #"${cfg.mediaDir}:/data"
      ];

      environmentFiles = [ secrets.unpackerr-env.path ];

      environment = {
        # General config
        "UN_DEBUG" = "true";
        "UN_LOG_FILE" = "";
        "UN_LOG_FILES" = "1";
        "UN_LOG_FILE_MB" = "10";
        "UN_INTERVAL" = "5m";
        "UN_START_DELAY" = "1m";
        "UN_RETRY_DELAY" = "5m";
        "UN_MAX_RETRIES" = "3";
        "UN_PARALLEL" = "1";
        "UN_FILE_MODE" = "0644";
        "UN_DIR_MODE" = "0755";
        # Sonarr Config
        "UN_SONARR_0_URL" = "http://sonarr:8989";
        # "UN_SONARR_0_API_KEY" = "";
        "UN_SONARR_0_PATHS_0" = "/data/downloads/completed/tv";
        "UN_SONARR_0_PROTOCOLS" = "torrent";
        "UN_SONARR_0_TIMEOUT" = "10s";
        "UN_SONARR_0_DELETE_ORIG" = "false";
        "UN_SONARR_0_DELETE_DELAY" = "5m";
        # Radarr Config
        "UN_RADARR_0_URL" = "http://radarr:7878";
        # "UN_RADARR_0_API_KEY" = "";
        "UN_RADARR_0_PATHS_0" = "/data/downloads/completed/movies";
        "UN_RADARR_0_PROTOCOLS" = "torrent";
        "UN_RADARR_0_TIMEOUT" = "10s";
        "UN_RADARR_0_DELETE_ORIG" = "false";
        "UN_RADARR_0_DELETE_DELAY" = "5m";
      };

      extraOptions = [
        "--pull=always"
        "--network=internal"
        "--security_opt=no-new-privileges"
      ];
    };

  };

}
