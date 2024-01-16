# modules.bazarr.enable = true;
{ config, lib, pkgs, this, ... }:

let
   
  image = "ghcr.io/onedr0p/bazarr";
  version = "rolling";

  cfg = config.modules.bazarr;
  inherit (lib) mkIf mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.bazarr = {
    enable = options.mkEnableOption "bazarr"; 
    hostName = mkOption {
      type = types.str; 
      default = "bazarr.${config.networking.fqdn}";
      description = "FQDN for the bazarr instance";
    };
    port = mkOption {
      type = types.port;
      default = 6767; 
    };
    configDir = mkOption {
      type = types.path;
      default = "/var/lib/bazarr";
    };
  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.bazarr = 917;
    ids.gids.bazarr = 917;

    users = {
      users = {

        # Add user to the bazarr group
        bazarr = {
          isSystemUser = true;
          group = "bazarr";
          description = "bazarr daemon user";
          home = cfg.configDir;
          uid = config.ids.uids.bazarr;
        };

      # Add admins to the bazarr group
      } // extraGroups this.admins [ "bazarr" ];

      # Create group
      groups.bazarr = {
        gid = config.ids.gids.bazarr;
      };

    };

    # Ensure data directory exists
    file."${cfg.configDir}" = {
      type = "dir"; mode = 0755; 
      user = config.ids.uids.bazarr; 
      group = config.ids.gids.bazarr;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # NixOS bazarr does not support changing settings
    virtualisation.oci-containers.containers.bazarr = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.bazarr}:${toString config.ids.gids.bazarr}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}:/config"
        #"${cfg.mediaDir}:/data"
      ];

      environment = {
        PUID = "${toString config.ids.uids.bazarr}";
        PGID = "${toString config.ids.gids.bazarr}";
      };
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.bazarr.rule" = "Host(`${cfg.hostName}`)";
        # "traefik.http.routers.bazarr.middlewares" = "chain-authelia@file";        
        "traefik.http.routers.bazarr.tls.certresolver" = "resolver-dns";
        "traefik.http.services.bazarr.loadbalancer.server.port" = "${toString cfg.port}";
      };
    };

  };

}
