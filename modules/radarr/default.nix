# modules.radarr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "ghcr.io/onedr0p/radarr";
  version = "rolling";
  port = 7878;

  cfg = config.modules.radarr;
  inherit (lib) mkIf mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.radarr = {
    enable = options.mkEnableOption "radarr"; 
    hostName = mkOption {
      type = types.str; 
      default = "radarr.${config.networking.domain}";
      description = "FQDN for the radarr instance";
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
          createHome = true;
          homeMode = "0755";
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

    backup.localPaths = [
      "${cfg.configDir}"
    ];

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
        # "${vars.mainArray}/Media/Downloads:/downloads"
        #     "${vars.mainArray}/Media/Movies:/movies"
      ];

      extraOptions = [
        "--pull=always"
        "--network=internal"
      ];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.radarr.entrypoints" = "websecure";
        "traefik.http.routers.radarr.middlewares" = "authelia@file";
        "traefik.http.services.radarr.loadbalancer.server.port" = "${toString port}";

        "homepage.group" = "Arr";
        "homepage.name" = "Radarr";
        "homepage.icon" = "radarr.svg";
        "homepage.href" = "https://${cfg.hostName}:444";
        "homepage.description" = "Movie PVR";
        "homepage.widget.type" = "radarr";
        "homepage.widget.key" = "{{HOMEPAGE_FILE_RADARR_KEY}}";
        "homepage.widget.url" = "http://radarr:${toString port}";
      };
    };

  };

}
