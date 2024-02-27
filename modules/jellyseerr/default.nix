# modules.jellyseerr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "fallenbagel/jellyseerr";
  version = "latest";
  port = 5055;

  cfg = config.modules.jellyseerr;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.jellyseerr = {
    enable = options.mkEnableOption "jellyseerr"; 
    hostName = mkOption {
      type = types.str; 
      default = "jellyseerr.${config.networking.domain}";
      description = "FQDN for the jellyseerr instance";
    };
    configDir= mkOption {
      type = types.str; 
      default = "/var/lib/jellyseerr"; 
    };
  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.jellyseerr = lib.mkForce 925;
    ids.gids.jellyseerr = lib.mkForce 925;

    users = {
      users = {

        jellyseerr = {
          isSystemUser = true;
          group = "jellyseerr";
          description = "jellyseerr daemon user";
          home = cfg.configDir;
          createHome = true;
          homeMode = "0755";
          uid = config.ids.uids.jellyseerr;
        };

      # Add admins to the jellyseerr group
      } // extraGroups this.admins [ "jellyseerr" ];

      # Create group
      groups.jellyseerr = {
        gid = config.ids.gids.jellyseerr;
      };

      # groups.media.members = [ "jellyseerr" ];

    };

    backup.localPaths = [
      "${cfg.configDir}"
    ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.jellyseerr = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.jellyseerr}:${toString config.ids.gids.jellyseerr}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}:/app/config"
      ];

      extraOptions = [
        "--pull=always"
        "--network=internal"
      ];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.jellyseerr.entrypoints" = "websecure";
        "traefik.http.routers.jellyseerr.rule" = "Host(`${cfg.hostName}`)";
        "traefik.http.routers.jellyseerr.middlewares" = "authelia@file";
        "traefik.http.services.jellyseerr.loadbalancer.server.port" = "${toString port}";

        "homepage.group" = "Arr";
        "homepage.name" = "jellyseerr";
        "homepage.icon" = "jellyseerr.svg";
        "homepage.href" = "https://${cfg.hostName}:444";
        "homepage.description" = "Request management";
        "homepage.widget.type" = "jellyseerr";
        "homepage.widget.key" = "{{HOMEPAGE_FILE_JELLYSEERR_KEY}}";
        "homepage.widget.url" = "http://jellyseerr:${toString port}";
      };
    };

  };

}
