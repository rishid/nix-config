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
      default = "overseerr.${config.networking.fqdn}";
      description = "FQDN for the overseerr instance";
    };

    dataDir = mkOption {
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
          home = cfg.dataDir;
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
    file."${cfg.dataDir}" = {
      type = "dir"; mode = 775; 
      user = config.users.users.overseerr.uid; 
      group = config.users.groups.overseerr.gid;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.overseerr = {
      image = "${image}:${version}";
      autoStart = true;

      # Run as overseerr user
      user = with config.ids; "${toString uids.overseerr}:${toString gids.overseerr}";

      # Traefik labels
      extraOptions = [
         "--pull=always"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.overseerr.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.overseerr.tls.certresolver=resolver-dns"
        # "--label=traefik.http.routers.overseerr.middlewares=local@file"
        "--label=traefik.http.routers.overseerr-rtr.service=overseerr-svc"
        "--label=traefik.http.services.overseerr-svc.loadbalancer.server.port=5055"
      ];

      volumes = [ "${cfg.dataDir}:/app/config" ];

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
