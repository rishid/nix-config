# modules.bazarr.enable = true;
{ config, lib, pkgs, this, ... }:

let
   
  image = "ghcr.io/onedr0p/bazarr";
  version = "rolling";
  port = 6767;

  cfg = config.modules.bazarr;
  inherit (lib) mkIf mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.bazarr = {
    enable = options.mkEnableOption "bazarr"; 
    hostName = mkOption {
      type = types.str; 
      default = "bazarr.${config.networking.domain}";
      description = "FQDN for the bazarr instance";
    };
    configDir = mkOption {
      type = types.path;
      default = "/var/lib/bazarr";
    };
  }; 

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.bazarr = 917;
    ids.gids.bazarr = 917;

    users = {
      users = {

        bazarr = {
          isSystemUser = true;
          group = "bazarr";
          description = "bazarr daemon user";
          home = cfg.configDir;
          createHome = true;
          homeMode = "0755";
          uid = config.ids.uids.bazarr;
        };

      # Add admins to the bazarr group
      } // extraGroups this.admins [ "bazarr" ];

      # Create group
      groups.bazarr = {
        gid = config.ids.gids.bazarr;
      };

      groups.media.members = [ "bazarr" ];

    };

    backup.localPaths = [
      "${cfg.configDir}"
    ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    # NixOS bazarr does not support changing settings
    virtualisation.oci-containers.containers.bazarr = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.bazarr}:${toString config.ids.gids.bazarr}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}:/config"
        #"${cfg.mediaDir}:/data"
      ];

      extraOptions = [
        "--pull=always"
        "--network=internal"
      ];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.bazarr.entrypoints" = "websecure";
        "traefik.http.routers.bazarr.middlewares" = "authelia@file";
        "traefik.http.services.bazarr.loadbalancer.server.port" = "${toString port}";

        "homepage.group" = "Arr";
        "homepage.name" = "Bazarr";
        "homepage.icon" = "bazarr.svg";
        "homepage.href" = "https://${cfg.hostName}:444";
        "homepage.description" = "Subtitles";
        "homepage.widget.type" = "bazarr";
        "homepage.widget.key" = "{{HOMEPAGE_FILE_BAZARR_KEY}}";
        "homepage.widget.url" = "http://bazarr:${toString port}";
      };
    };

  };

}
