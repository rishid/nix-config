{ config, lib, pkgs, ... }:

let

  cfg = config.modules.authelia;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {
        
    services.lldap.enable = true;

    # reference: https://github.com/lldap/lldap/blob/main/lldap_config.docker_template.toml
    services.lldap.settings = {
      verbose = true;

      ldap_host = "127.0.0.1";
      ldap_port = 3890;

      http_host = "127.0.0.1";
      http_port = 17170;

      http_url = "https://lldap.dhupar.xyz";

      ldap_base_dn = "dc=dhupar,dc=xyz";

      ldap_user_dn = "admin";
      ldap_user_email = "admin@dhupar.xyz";

      database_url = "sqlite:///var/lib/lldap/users.db?mode=rwc";
      # key_file = "/var/lib/lldap/private-key";

      environment = {
        # LLDAP_JWT_SECRET_FILE = "%d/jwt-secret";
        LLDAP_JWT_SECRET = "MJ-d@2c1c1m6anA%p3X;MA6V'7j6QW/J"; # TODO: replace with age
        LLDAP_LDAP_USER_PASS = "dolphins"; # TODO: fix me
      };
    };

    # systemd.services.lldap = {
    #   serviceConfig = {
    #     LoadCredential = [
    #       "jwt-secret:${config.age.secrets.lldap-jwt-secret.path}"
    #     ];
    #   };
    # };

    # LLDAP_DATABASE_URL = "postgresql:///lldap?host=/run/postgresql";
    # services.postgresql = {
    #   ensureDatabases = [ "lldap" ];
    #   ensureUsers = [{
    #     name = "lldap";
    #     ensurePermissions = {
    #       "DATABASE lldap" = "ALL PRIVILEGES";
    #     };
    #   }];
    # };

    services.traefik.dynamicConfigOptions.http = {
      routers.lldap = {
        entrypoints = "websecure";
        rule = "Host(`lldap.dhupar.xyz`)";
        tls.certresolver = "resolver-dns";        
        # middlewares = [ "tailscale-ips" ];
        service = "lldap";
      };
      services.lldap.loadBalancer.servers = [{ url = "http://127.0.0.1:17170"; }];
    };

    # age.secrets.lldap-jwt-secret.file = ./.lldap-jwt-secret.age;

  };
}
