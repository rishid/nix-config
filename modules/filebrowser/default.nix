# modules.filebrowser.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "filebrowser/filebrowser";
  version = "latest";

  cfg = config.modules.filebrowser;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.filebrowser = {
    enable = options.mkEnableOption "filebrowser"; 
    hostName = mkOption {
      type = types.str; 
      default = "filebrowser.${config.networking.domain}";
      description = "FQDN for the filebrowser instance";
    };
    port = mkOption {
      type = types.port;
      default = 80; 
    };
    configDir= mkOption {
      type = types.str; 
      default = "/var/lib/filebrowser"; 
    };
  };

  config = mkIf cfg.enable {

    users = {
      users = {
        filebrowser = {
          isSystemUser = true;
          # group = "filebrowser";
          description = "filebrowser daemon user";
          home = cfg.configDir;
          extraGroups = [ "filebrowser" ];
          createHome = true;
        };

      # Add admins to the filebrowser group
      };# // extraGroups this.admins [ "filebrowser" ];

      # Create group
      # groups.filebrowser = {
      #   gid = config.ids.gids.filebrowser;
      # };

    };

    # users.groups.filebrowser = { name = "filebrowser"; };

    # Ensure data directory exists
    # file."${cfg.configDir}" = {
    #   type = "dir"; mode = 0755; 
    #   user = config.ids.uids.filebrowser; 
    #   group = config.ids.gids.filebrowser;
    # };

    backup.localPaths = [
      "${cfg.configDir}"
    ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    # NixOS filebrowser version is v3
    virtualisation.oci-containers.containers.filebrowser = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.filebrowser}:${toString config.ids.gids.filebrowser}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}:/config"
        #"${cfg.mediaDir}:/data"
      ];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.filebrowser.rule" = "Host(`${cfg.hostName}`)";
        # "traefik.http.routers.filebrowser.middlewares" = "chain-authelia@file";        
        "traefik.http.routers.filebrowser.tls.certresolver" = "resolver-dns";
        "traefik.http.services.filebrowser.loadbalancer.server.port" = "${toString cfg.port}";
      };
    };

  };

}
