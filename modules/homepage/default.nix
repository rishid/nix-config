# modules.homepage.enable = true;
{ config, lib, pkgs, this, ... }:

let
  inherit (this.lib) extraGroups;

  cfg = config.modules.homepage;
  homepage = config.services.homepage-dashboard;
  format = pkgs.formats.yaml { };
  configDir = "/var/lib/homepage-dashboard";

  homepageSettings = {
    docker = format.generate "docker.yaml" (import ./docker.nix);
    services = pkgs.writeTextFile {
      name = "services.yaml";
      text = builtins.readFile ./services.yaml;
    };
    settings = format.generate "settings.yaml" (import ./settings.nix);
    bookmarks = format.generate "bookmarks.yaml" (import ./bookmarks.nix);
    widgets = pkgs.writeTextFile {
      name = "widgets.yaml";
      text = builtins.readFile ./widgets.yaml;
    };
  };
in
{
  options.modules.homepage = with lib; {
    enable = mkEnableOption "homepage";
    hostName = mkOption {
      type = types.str; 
      default = "home.${config.networking.domain}";
      description = "FQDN for the sonarr instance";
    };
    # settings = mkOption {
    #   type = types.attrs;
    #   default = { };
    # };
    # services = mkOption {
    #   type = types.listOf types.attrs;
    #   default = [ ];
    # };
    # widgets = mkOption {
    #   type = types.listOf types.attrs;
    #   default = [ ];
    # };
    # bookmarks = mkOption {
    #   type = types.listOf types.attrs;
    #   default = [ ];
    # };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [ glances ];

    systemd.services.glances = {
      description = "Glances";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.glances}/bin/glances -w";
        Type = "simple";
      };
    };

    ids.uids.homepage = lib.mkForce 922;
    ids.gids.homepage = lib.mkForce 922;

    users = {
      users = {
        homepage = {
          isSystemUser = true;
          group = "homepage";
          description = "homepage daemon user";
          home = configDir;
          createHome = true;
          homeMode = "0755";
          uid = config.ids.uids.homepage;
        };
      # Add admins to the homepage group
      } // extraGroups this.admins [ "homepage" ];

      # Create group
      groups.homepage = {
        gid = config.ids.gids.homepage;
      };
    };

    backup.localPaths = [
      "${configDir}"
    ];

    modules.traefik = {
      enable = true;
      # TODO: something to look at:
      # https://github.com/LongerHV/nixos-configuration/blob/424d51e746951244369c21a45acf79d050244f8c/modules/nixos/homelab/traefik.nix
      # services.homepage.port = homepage.listenPort;
    };

    # services.traefik.dynamicConfigOptions.http = {
    #   routers.homepage = {
    #     entrypoints = "websecure";
    #     rule = "Host(`home.dhupar.xyz`)";
    #     tls.certresolver = "letsencrypt";
    #     # middlewares = "local@file";
    #     service = "homepage";
    #   };
    #   services.homepage.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString homepage.listenPort}"; }];
    # };

    virtualisation.oci-containers.containers.homepage = {
      image = "ghcr.io/gethomepage/homepage:v0.8.0";
      # user = "${toString config.ids.uids.homepage}:${toString config.ids.gids.homepage}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${configDir}:/app/config/"        
        "${homepageSettings.bookmarks}:/app/config/bookmarks.yaml"
        "${homepageSettings.docker}:/app/config/docker.yaml"
        "${homepageSettings.services}:/app/config/services.yaml"
        "${homepageSettings.settings}:/app/config/settings.yaml"
        "${homepageSettings.widgets}:/app/config/widgets.yaml"
        # "${homepageCustomCss}:/app/custom.css"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        # "/run/podman/podman.sock:/var/run/docker.sock"
        "${config.age.secrets.sonarr-api-key.path}:/app/config/sonarr.key"
        "${config.age.secrets.radarr-api-key.path}:/app/config/radarr.key"
        "${config.age.secrets.jellyfin-api-key.path}:/app/config/jellyfin.key"
      ];
      
      ports = [ "3000:3000" ];

      extraOptions = [
        "--network=internal"
      ];

      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.homepage.rule" = "Host(`${cfg.hostName}`)";
        # "traefik.http.routers.homepage.middlewares" = "chain-authelia@file";        
        "traefik.http.routers.homepage.tls.certresolver" = "letsencrypt";
        "traefik.http.services.homepage.loadbalancer.server.port" = "3000";
      };

      environment = {
        # TZ = vars.timeZone;
        LOG_LEVEL = "debug";
        HOMEPAGE_FILE_SONARR_KEY = "/app/config/sonarr.key";
        HOMEPAGE_FILE_RADARR_KEY = "/app/config/radarr.key";
        HOMEPAGE_FILE_JELLYFIN_KEY = "/app/config/jellyfin.key";
      };
        # environmentFiles = [
        #   config.age.secrets.paperless.path
        # ];
    };

    # services.homepage-dashboard.enable = true;
    # systemd.services.homepage-dashboard = {
    #   preStart = ''
    #     ln -sf ${format.generate "settings.yaml" cfg.settings} ${configDir}/settings.yaml
    #     ln -sf ${format.generate "services.yaml" cfg.services} ${configDir}/services.yaml
    #     ln -sf ${format.generate "widgets.yaml" cfg.widgets} ${configDir}/widgets.yaml
    #     ln -sf ${format.generate "bookmarks.yaml" cfg.bookmarks} ${configDir}/bookmarks.yaml
    #   '';
    # };

  };
}
