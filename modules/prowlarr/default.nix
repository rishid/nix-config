# modules.prowlarr.enable = true;
{ config, lib, pkgs, this, ... }:

let
   
  image = "ghcr.io/onedr0p/prowlarr-develop";
  version = "rolling";

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
    port = mkOption {
      type = types.port;
      default = 9696; 
    };
    dataDir = mkOption {
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
          home = cfg.dataDir;
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
    file."${cfg.dataDir}" = {
      type = "dir"; mode = 0755; 
      user = config.ids.uids.prowlarr; 
      group = config.ids.gids.prowlarr;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # NixOS prowlarr does not support changing settings
    virtualisation.oci-containers.containers.prowlarr = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.prowlarr}:${toString config.ids.gids.prowlarr}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.dataDir}:/config"
      ];

      environment = {
        PUID = "${toString config.ids.uids.prowlarr}";
        PGID = "${toString config.ids.gids.prowlarr}";
      };
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.prowlarr.rule" = "Host(`${cfg.hostName}`)";
        # "traefik.http.routers.prowlarr.middlewares" = "chain-authelia@file";        
        "traefik.http.routers.prowlarr.tls.certresolver" = "resolver-dns";
        "traefik.http.services.prowlarr.loadbalancer.server.port" = "${toString cfg.port}";
      };
    };

  };

}
