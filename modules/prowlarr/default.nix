# modules.prowlarr.enable = true;
{ config, lib, pkgs, this, ... }:

let
   
  image = "ghcr.io/onedr0p/prowlarr-develop";
  version = "rolling";
  port = 9696;

  cfg = config.modules.prowlarr;
  inherit (lib) mkIf mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.prowlarr = {
    enable = options.mkEnableOption "prowlarr"; 
    hostName = mkOption {
      type = types.str; 
      default = "prowlarr.${config.networking.domain}";
      description = "FQDN for the Prowlarr instance";
    };
    configDir = mkOption {
      type = types.path;
      default = "/var/lib/prowlarr";
    };
  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.prowlarr = 916;
    ids.gids.prowlarr = 916;

    users = {
      users = {

        # Add user to the prowlarr group
        prowlarr = {
          isSystemUser = true;
          group = "prowlarr";
          description = "prowlarr daemon user";
          home = cfg.configDir;
          uid = config.ids.uids.prowlarr;
        };

      # Add admins to the prowlarr group
      } // extraGroups this.admins [ "prowlarr" ];

      # Create group
      groups.prowlarr = {
        gid = config.ids.gids.prowlarr;
      };

    };

    # Ensure data directory exists
    file."${cfg.configDir}" = {
      type = "dir"; mode = 0755; 
      user = config.ids.uids.prowlarr; 
      group = config.ids.gids.prowlarr;
    };

    backup.localPaths = [
      "${cfg.configDir}"
    ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    # NixOS prowlarr does not support changing settings
    virtualisation.oci-containers.containers.prowlarr = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.prowlarr}:${toString config.ids.gids.prowlarr}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}:/config"
      ];

      extraOptions = [
        "--pull=always"
        "--network=internal"
      ];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.prowlarr.entrypoints" = "websecure";
        "traefik.http.routers.prowlarr.middlewares" = "authelia@file";
        "traefik.http.services.prowlarr.loadbalancer.server.port" = "${toString port}";

        "homepage.group" = "Arr";
        "homepage.name" = "Prowlarr";
        "homepage.icon" = "prowlarr.svg";
        "homepage.href" = "https://${cfg.hostName}:444";
        "homepage.description" = "Torrent indexer";
      };
    };

  };

}
