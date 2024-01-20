# modules.sonarr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "ghcr.io/onedr0p/sonarr";
  version = "rolling";

  cfg = config.modules.sonarr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.sonarr = {
    enable = options.mkEnableOption "sonarr"; 
    hostName = mkOption {
      type = types.str; 
      default = "sonarr.${config.networking.domain}";
      description = "FQDN for the sonarr instance";
    };
    port = mkOption {
      type = types.port;
      default = 8989; 
    };
    configDir= mkOption {
      type = types.str; 
      default = "/var/lib/sonarr"; 
    };
  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.sonarr = lib.mkForce 919;
    ids.gids.sonarr = lib.mkForce 919;

    users = {
      users = {

        sonarr = {
          isSystemUser = true;
          group = "sonarr";
          description = "sonarr daemon user";
          home = cfg.configDir;
          uid = config.ids.uids.sonarr;
        };

      # Add admins to the sonarr group
      } // extraGroups this.admins [ "sonarr" ];

      # Create group
      groups.sonarr = {
        gid = config.ids.gids.sonarr;
      };

      groups.media.members = [ "sonarr" ];

    };

    # Ensure data directory exists
    file."${cfg.configDir}" = {
      type = "dir"; mode = 0755; 
      user = config.ids.uids.sonarr; 
      group = config.ids.gids.sonarr;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # NixOS sonarr version is v3
    virtualisation.oci-containers.containers.sonarr = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.sonarr}:${toString config.ids.gids.sonarr}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}:/config"
        #"${cfg.mediaDir}:/data"
      ];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.sonarr.rule" = "Host(`${cfg.hostName}`)";
        # "traefik.http.routers.sonarr.middlewares" = "chain-authelia@file";        
        "traefik.http.routers.sonarr.tls.certresolver" = "resolver-dns";
        "traefik.http.services.sonarr.loadbalancer.server.port" = "${toString cfg.port}";
      };
    };

    backup.fsBackups.arr = {
      paths = [
        "${cfg.configDir}"
      ];
    };

  };

}
