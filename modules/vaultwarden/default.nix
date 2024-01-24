{ config, lib, ... }:

let
  cfg = config.modules.vaultwarden;
  inherit (lib) mkIf mkBefore mkOption options types;
  port = 8222;
  smtpPort = 587;
in {
  options.modules.vaultwarden = {
    enable = options.mkEnableOption "vaultwarden"; 
    hostName = mkOption {
      type = types.str; 
      default = "vaultwarden.${config.networking.domain}";
    };
  };

  config = mkIf cfg.enable {

    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite";
      backupDir = "/var/backup/vaultwarden";
      config = {
        DOMAIN = "https://${cfg.hostName}";
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = "true";
        ROCKET_PORT = "${toString port}";

        PUSH_ENABLED = true;

        LOG_LEVEL="debug";

        # SMTP_HOST = "smtp.gmail.com";
        # SMTP_FROM = "vault@snakepi.eu.org";
        # SMTP_FROM_NAME = "Vaultwarden";
        # SMTP_SECURITY = "starttls";
        # SMTP_PORT = smtpPort;
        # SMTP_USERNAME = "jstengyufei";
      };
      environmentFile = config.age.secrets.vaultwarden-env.path;
    };

    backup.localPaths = [
      # Backup DB and persistent data (e.g. attachments)
      "${config.services.vaultwarden.backupDir}"
    ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    # networking.firewall.allowedTCPPorts = [ port smtpPort ];

    services.traefik.dynamicConfigOptions.http = {
      routers.vaultwarden = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        # tls.certresolver = "letsencrypt";
        middlewares = "authelia@file";
        service = "vaultwarden";
      };
      services.vaultwarden.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString port}"; }];
    };

    # "-l=homepage.group=Services"
    #       "-l=homepage.name=Vaultwarden"
    #       "-l=homepage.icon=bitwarden.svg"
    #       "-l=homepage.href=https://pass.${vars.domainName}"
    #       "-l=homepage.description=Password manager"

    # services.caddy.virtualHosts."vault.snakepi.xyz" = {
    #   logFormat = "output stdout";
    #   extraConfig = ''
    #     import ${config.sops.templates.cf-tls.path}

    #     header / {
    #       Strict-Transport-Security "max-age=31536000;"
    #       X-XSS-Protection "0"
    #       X-Frame-Options "SAMEORIGIN"
    #       X-Robots-Tag "noindex, nofollow"
    #       X-Content-Type-Options "nosniff"
    #       -Server
    #       -X-Powered-By
    #       -Last-Modified
    #     }

    #     reverse_proxy localhost:${toString port} {
    #       header_up X-Real-IP {remote_host}
    #     }
    #   '';
    # };

  };
}
