# modules.homepage.enable = true;
{ config, lib, pkgs, this, ... }:

let
  image = "ghcr.io/gethomepage/homepage";      
  version = "latest";
  port = 3000;

  cfg = config.modules.homepage;
  # homepage = config.services.homepage-dashboard;
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

  inherit (this.lib) extraGroups;
in
{
  options.modules.homepage = with lib; {
    enable = mkEnableOption "homepage";
    hostName = mkOption {
      type = types.str; 
      default = "home.${config.networking.domain}";
      description = "FQDN for the sonarr instance";
    };

    infrastructure-services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add to the infrastructure column";
      default = [];
    };
    home-services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add to the home column";
      default = [];
    };
    media-services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add to the media column";
      default = [];
    };

  };

  config = let
    settings = {
      # title = "Hades";
      # theme = "dark";
      # color = "slate";
      showStats = true;
    };
    settingsFile = builtins.toFile "homepage-settings.yaml" (builtins.toJSON settings);

    bookmarks = [
      {
        Administration = [
          { Source = [ { icon = "github.png"; href = "https://github.com/nikitawootten/infra"; } ]; }
          { Tailscale = [ { abbr = "TS"; href = "https://login.tailscale.com/admin/machines/"; } ]; }
          { Cloudflare = [ { icon = "cloudflare.png"; href = "https://dash.cloudflare.com/"; } ]; }
        ];
      }
      {
        Development = [
          { CyberChef = [ { icon = "cyberchef.png"; href = "https://gchq.github.io/CyberChef/"; } ]; }
          { "Nix Options Search" = [ { abbr = "NS"; href = "https://search.nixos.org/packages"; } ]; }
          { "Arion Documentation" = [ { abbr = "AD"; href = "https://docs.hercules-ci.com/arion/"; } ]; }
        ];
      }
    ];
    bookmarksFile = builtins.toFile "homepage-bookmarks.yaml" (builtins.toJSON bookmarks);

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          cputemp = true;
          uptime = true;
          disk = "/";
          units = "imperial";
          # label = "system";
        };
      }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
    ];
    widgetsFile = builtins.toFile "homepage-widgets.yaml" (builtins.toJSON widgets);

    docker = {
      my-docker.socket = "/var/run/docker.sock";
    };
    dockerFile = builtins.toFile "homepage-docker.yaml" (builtins.toJSON docker);

    services = [
      { Infrastructure = cfg.infrastructure-services; }
      { Home = cfg.home-services; }
      { Media = cfg.media-services; }
    ];
    servicesFile = builtins.toFile "homepage-services.yaml" (builtins.toJSON services);

  in 
    lib.mkIf cfg.enable {

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
      };

      virtualisation.oci-containers.containers.homepage = {
        image = "${image}:${version}";
        # user = "${toString config.ids.uids.homepage}:${toString config.ids.gids.homepage}";

        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${configDir}:/app/config/"        
          "${settingsFile}:/app/config/settings.yaml"
          "${servicesFile}:/app/config/services.yaml"
          "${bookmarksFile}:/app/config/bookmarks.yaml"
          "${widgetsFile}:/app/config/widgets.yaml"
          "${dockerFile}:/app/config/docker.yaml"

          "/var/run/docker.sock:/var/run/docker.sock:ro"
          # "/run/podman/podman.sock:/var/run/docker.sock"

          "${config.age.secrets.bazarr-api-key.path}:/app/config/bazarr.key"
          "${config.age.secrets.sonarr-api-key.path}:/app/config/sonarr.key"
          "${config.age.secrets.radarr-api-key.path}:/app/config/radarr.key"
          "${config.age.secrets.jellyfin-api-key.path}:/app/config/jellyfin.key"
          "${config.age.secrets.jellyseerr-api-key.path}:/app/config/jellyseerr.key"
          "${config.age.secrets.immich-api-key.path}:/app/config/immich.key"
        ];

        extraOptions = [
          "--pull=always"
          "--network=internal"
        ];

        labels = {
          "autoheal" = "true";
          "traefik.enable" = "true";
          "traefik.http.routers.homepage.entrypoints" = "websecure";        
          "traefik.http.routers.homepage.rule" = "Host(`${cfg.hostName}`) || Host(`dhupar.xyz`) || Host(`www.dhupar.xyz`)";
          "traefik.http.routers.homepage.middlewares" = "authelia@file";
          "traefik.http.services.homepage.loadbalancer.server.port" = "${toString port}";
        };

        environment = {
          LOG_LEVEL = "debug";
          HOMEPAGE_FILE_BAZARR_KEY = "/app/config/bazarr.key";
          HOMEPAGE_FILE_SONARR_KEY = "/app/config/sonarr.key";
          HOMEPAGE_FILE_RADARR_KEY = "/app/config/radarr.key";
          HOMEPAGE_FILE_JELLYFIN_KEY = "/app/config/jellyfin.key";
          HOMEPAGE_FILE_JELLYSEERR_KEY = "/app/config/jellyseerr.key";
          HOMEPAGE_FILE_IMMICH_KEY = "/app/config/immich.key";
        };
      };
  };
}
