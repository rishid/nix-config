# modules.overseerr.enable = true;
{ config, lib, pkgs, this, ... }:

let

  # https://github.com/sctx/overseerr/releases
  image = "sctx/overseerr";
  version = "develop";

  cfg = config.modules.overseerr;

  inherit (lib) mkIf mkOption options types strings mkBefore;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.overseerr = {

    enable = options.mkEnableOption "overseerr"; 

    hostName = mkOption {
      type = types.str;
      default = "overseerr.${config.networking.domain}";
      description = "FQDN for the overseerr instance";
    };

    configDir = mkOption {
      type = types.path;
      default = "/var/lib/overseerr";
    };

  };

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.overseerr = 915;
    ids.gids.overseerr = 915;

    users = {
      users = {

        # Add user to the overseerr group
        overseerr = {
          isSystemUser = true;
          group = "overseerr";
          description = "overseerr daemon user";
          home = cfg.configDir;
          uid = config.ids.uids.overseerr;
        };

      # Add admins to the overseerr group
      } // extraGroups this.admins [ "overseerr" ];

      # Create group
      groups.overseerr = {
        gid = config.ids.gids.overseerr;
      };

    };

    # Ensure data directory exists
    file."${cfg.configDir}" = {
      type = "dir"; mode = 775; 
      user = config.users.users.overseerr.uid; 
      group = config.users.groups.overseerr.gid;
    };

    backup.localPaths = [
      "${cfg.configDir}"
    ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.overseerr = {
      image = "${image}:${version}";
      user = with config.ids; "${toString uids.overseerr}:${toString gids.overseerr}";

      volumes = [ "${cfg.configDir}:/app/config" ];

      extraOptions = [
        "--pull=always"
        "--network=internal"
      ];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.overseerr.entrypoints" = "websecure";
        "traefik.http.routers.overseerr.rule" = "Host(`${cfg.hostName}`)";
        "traefik.http.routers.overseerr.middlewares" = "authelia@file";
        "traefik.http.services.overseerr.loadbalancer.server.port" = "5055";

        "homepage.group" = "Arr";
        "homepage.name" = "Overseerr";
        "homepage.icon" = "overseerr.svg";
        "homepage.href" = "https://${cfg.hostName}:444";
        "homepage.description" = "Service to request movies and TV shows";
        "homepage.widget.type" = "overseerr";
        "homepage.widget.key" = "{{HOMEPAGE_FILE_OVERSEERR_KEY}}";
        "homepage.widget.url" = "http://overseerr:5055";
      };

    };

    # Extend systemd service
    # systemd.services.docker-overseerr = {
    #   after = [ "traefik.service" ];
    #   requires = [ "traefik.service" ];
    #   preStart = with config.virtualisation.oci-containers.containers; ''
    #     docker pull ${overseerr.image};
    #   '';
    # };

  };

}
