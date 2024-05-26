# modules.filebrowser.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "filebrowser/filebrowser";
  version = "latest";

  cfg = config.modules.filebrowser;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (this.lib) extraGroups;

in {

  options.modules.filebrowser = {
    enable = options.mkEnableOption "filebrowser"; 
    hostName = mkOption {
      type = types.str; 
      default = "filebrowser.${config.networking.domain}";
      description = "FQDN for the filebrowser instance";
    };
    configDir= mkOption {
      type = types.str; 
      default = "/var/lib/filebrowser"; 
    };
  };

  config = mkIf cfg.enable {

    ids.uids.filebrowser = lib.mkForce 921;
    ids.gids.filebrowser = lib.mkForce 921;

    users = {
      users = {
        filebrowser = {
          isSystemUser = true;
          group = "filebrowser";
          description = "filebrowser daemon user";
          home = cfg.configDir;
          createHome = true;
          homeMode = "0755";
          uid = config.ids.uids.filebrowser;
        };

      # Add admins to the filebrowser group
      } // extraGroups this.admins [ "filebrowser" ];

      # Create group
      groups.filebrowser = {
        gid = config.ids.gids.filebrowser;
      };

    };

    # Database has to exist before starting container
    file."${cfg.configDir}/filebrowser.db" = {
      type = "file"; mode = 0644; 
      user = config.ids.uids.filebrowser; 
      group = config.ids.gids.filebrowser;
    };

    backup.localPaths = [
      "${cfg.configDir}"
    ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.filebrowser = {
      image = "${image}:${version}";
      # user = "filebrowser:filebrowser";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}/filebrowser.db:/database.db"
        # "${cfg.configDir}/.filebrowser.json:/.filebrowser.json"
        "${config.paths.poolArray}:/srv"
      ];

      environment = {
        FB_LOG = "stdout";
        FB_NOAUTH = "true";
      }; 
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.filebrowser.entrypoints" = "websecure";
        "traefik.http.routers.filebrowser.rule" = "Host(`${cfg.hostName}`)";
        "traefik.http.routers.filebrowser.middlewares" = "authelia@file";
        "traefik.http.services.filebrowser.loadbalancer.server.port" = "80";

        "homepage.group" = "Utils";
        "homepage.name" = "File Explorer";
        "homepage.description" = "Filebrowser";
        "homepage.icon" = "filebrowser.svg";
        "homepage.href" = "https://${cfg.hostName}:444";
      };
    };

    

  };

}
