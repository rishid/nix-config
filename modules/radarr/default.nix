# modules.radarr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "ghcr.io/onedr0p/radarr";
  version = "rolling";

  cfg = config.modules.radarr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.radarr = {
    enable = options.mkEnableOption "radarr"; 
    hostName = mkOption {
      type = types.str; 
      default = "radarr.${config.networking.fqdn}";
    };
    port = mkOption {
      type = types.port;
      default = 7878; 
    };
    configDir = mkOption {
      type = types.str; 
      default = "/var/lib/radarr"; 
    };
  }; 

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.radarr = lib.mkForce 920;
    ids.gids.radarr = lib.mkForce 920;

    users = {
      users = {

        radarr = {
          isSystemUser = true;
          group = "radarr";
          description = "radarr daemon user";
          home = cfg.configDir;
          uid = config.ids.uids.radarr;
        };

      # Add admins to the radarr group
      } // extraGroups this.admins [ "radarr" ];

      # Create group
      groups.radarr = {
        gid = config.ids.gids.radarr;
      };

      groups.media.members = [ "radarr" ];

    };

    # Ensure data directory exists
    file."${cfg.configDir}" = {
      type = "dir"; mode = 0755; 
      user = config.ids.uids.radarr; 
      group = config.ids.gids.radarr;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # NixOS radarr version is v3
    virtualisation.oci-containers.containers.radarr = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.radarr}:${toString config.ids.gids.radarr}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}:/config"
        #"${cfg.mediaDir}:/data"
      ];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.radarr.rule" = "Host(`${cfg.hostName}`)";
        # "traefik.http.routers.radarr.middlewares" = "chain-authelia@file";        
        "traefik.http.routers.radarr.tls.certresolver" = "resolver-dns";
        "traefik.http.services.radarr.loadbalancer.server.port" = "${toString cfg.port}";
      };
    };

  };

}
