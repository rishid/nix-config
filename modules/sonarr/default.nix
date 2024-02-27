# modules.sonarr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "ghcr.io/onedr0p/sonarr";
  version = "rolling";
  port = 8989;

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
    configDir = mkOption {
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
          createHome = true;
          homeMode = "0755";
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

    backup.localPaths = [
      "${cfg.configDir}"
    ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    # NixOS sonarr version is v3
    virtualisation.oci-containers.containers.sonarr = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.sonarr}:${toString config.ids.gids.sonarr}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}:/config"
        "${config.paths.media}:/data"
        #"${cfg.mediaDir}:/data"
      ];

      extraOptions = [
        "--pull=always"
        "--network=internal"
      ];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.sonarr.entrypoints" = "websecure";
        "traefik.http.routers.sonarr.middlewares" = "authelia@file";
        "traefik.http.services.sonarr.loadbalancer.server.port" = "${toString port}";

        "homepage.group" = "Arr";
        "homepage.name" = "Sonarr";
        "homepage.icon" = "sonarr.svg";
        "homepage.href" = "https://${cfg.hostName}:444";
        "homepage.description" = "Smart PVR";
        "homepage.widget.type" = "sonarr";
        "homepage.widget.key" = "{{HOMEPAGE_FILE_SONARR_KEY}}";
        "homepage.widget.url" = "http://sonarr:${toString port}";
      };
    };

  };

}
