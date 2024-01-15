# modules.transmission-ovpn.enable = true;
{ config, lib, pkgs, this, ... }:

let

  # https://github.com/haugene/docker-transmission-openvpn
  image = "haugene/transmission-openvpn";      
  version = "latest";

  cfg = config.modules.transmission-ovpn;

  inherit (lib) mkIf mkOption options types strings mkBefore;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;


in {

  options.modules.transmission-ovpn = {

    enable = options.mkEnableOption "transmission-ovpn"; 

    hostName = mkOption {
      type = types.str;
      default = "trans.${config.networking.fqdn}";
      description = "FQDN for the Transmission instance";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/transmission-ovpn";
    };

  };

  # todo: look at auto adding to a homepage
  # https://github.com/nikitawootten/infra/blob/c56abade2ee7edfe96e8b50ed5d963bc6f43e928/hosts/hades/lab/homepage.nix#L80

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.tranmission = 914;
    ids.gids.tranmission = 914;

    users = {
      users = {

        # Add user to the transmission group
        transmission = {
          isSystemUser = true;
          group = "transmission";
          description = "transmission daemon user";
          home = cfg.dataDir;
          uid = config.ids.uids.transmission;
        };

      # Add admins to the transmission group
      } // extraGroups this.admins [ "transmission" ];

      # Create group
      groups.transmission = {
        gid = config.ids.gids.transmission;
      };

    };

    # Ensure data directory exists
    file."${cfg.dataDir}" = {
      type = "dir"; mode = 775; 
      user = config.users.users.transmission.uid; 
      group = config.users.groups.transmission.gid;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.transmission-ovpn = {
      image = "${image}:${version}";

      # Run as transmission user
      user = with config.ids; "${toString uids.transmission}:${toString gids.transmission}";

      # Traefik labels
      # TODO: should switch to `labels` format
      # consider creating mkTraefikLabels
      # https://github.com/nikitawootten/infra/blob/c56abade2ee7edfe96e8b50ed5d963bc6f43e928/hosts/hades/lab/infra/traefik.nix#L95
      extraOptions = [
        "--pull=always"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.transmission-ovpn.rule=Host(`${cfg.hostName}`)"
        "--label=traefik.http.routers.transmission-ovpn.tls.certresolver=resolver-dns"
        # "--label=traefik.http.routers.transmission-ovpn.middlewares=local@file"
        "--label=traefik.http.routers.transmission-vpn-rtr.service=transmission-vpn-svc"
        "--label=traefik.http.services.transmission-vpn-svc.loadbalancer.server.port=9091"
        "--cap-add=NET_ADMIN"
      ];

      # environmentFiles = [ config.age.secrets.transmission-ovpn.path ];

      # volumes = [ "${cfg.dataDir}:/data" ];
     
      # volumes = [
      #   "${config.lib.lab.mkConfigDir "transmission-ovpn"}/:/config"
      #   "${config.personal.lab.media.media-dir}/torrents/:/data"
      # ];
    };

    # TODO: I think transmission requires, something to review
    networking.enableIPv6 = false;

    # Extend systemd service
    # systemd.services.docker-silverbullet = {
    #   after = [ "traefik.service" ];
    #   requires = [ "traefik.service" ];
    #   preStart = with config.virtualisation.oci-containers.containers; ''
    #     docker pull ${silverbullet.image};
    #   '';
    # };

  };

}
