# modules.homepage.enable = true;
{ config, lib, pkgs, this, ... }:

let
  cfg = config.modules.homepage;
  homepage = config.services.homepage-dashboard;
  format = pkgs.formats.yaml { };
  configDir = "/var/lib/homepage-dashboard";
in
{
  options.modules.homepage = with lib; {
    enable = mkEnableOption "homepage";
    settings = mkOption {
      type = types.attrs;
      default = { };
    };
    services = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
    };
    widgets = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
    };
    bookmarks = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    modules.traefik = {
      enable = true;
      # TODO: something to look at:
      # https://github.com/LongerHV/nixos-configuration/blob/424d51e746951244369c21a45acf79d050244f8c/modules/nixos/homelab/traefik.nix
      # services.homepage.port = homepage.listenPort;
    };

    services.traefik.dynamicConfigOptions.http = {
      routers.homepage = {
        entrypoints = "websecure";
        rule = "Host(`home.dhupar.xyz`)";
        tls.certresolver = "resolver-dns";
        # middlewares = "local@file";
        service = "homepage";
      };
      services.homepage.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString homepage.listenPort}"; }];
    };

    services.homepage-dashboard.enable = true;
    systemd.services.homepage-dashboard = {
      preStart = ''
        ln -sf ${format.generate "settings.yaml" cfg.settings} ${configDir}/settings.yaml
        ln -sf ${format.generate "services.yaml" cfg.services} ${configDir}/services.yaml
        ln -sf ${format.generate "widgets.yaml" cfg.widgets} ${configDir}/widgets.yaml
        ln -sf ${format.generate "bookmarks.yaml" cfg.bookmarks} ${configDir}/bookmarks.yaml
      '';
    };

    backup.localPaths = [
      "${configDir}"
    ];
  };
}
