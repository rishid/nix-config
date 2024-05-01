{ config, lib, pkgs, ... }:

let

  cfg = config.modules.authelia;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # users.groups.lldap = { };
    # users.users.lldap = {
    #   name = "lldap";
    #   group = "lldap";
    #   isSystemUser = true;
    # };
    users.groups.secrets = {
      members = [ "lldap" ];
    };

    # reference: https://github.com/lldap/lldap/blob/main/lldap_config.docker_template.toml
    services.lldap = {
      enable = true;

      settings = {
        verbose = true;

        ldap_host = "127.0.0.1";
        ldap_port = 3890;

        http_url = "https://lldap.dhupar.xyz";
        http_host = "127.0.0.1";
        http_port = 17170;        

        ldap_base_dn = "dc=dhupar,dc=xyz";

        ldap_user_dn = "admin";
        ldap_user_email = "admin@dhupar.xyz";

        database_url = "sqlite:///var/lib/lldap/users.db?mode=rwc";
      };

      environment = {
        LLDAP_JWT_SECRET_FILE = toString config.age.secrets.lldap-jwt-secret.path;
        LLDAP_LDAP_USER_PASS_FILE = toString config.age.secrets.lldap-user-password.path;

        # RUST_LOG = "debug";
      };
    };

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

    backup.localPaths = [
      "/var/lib/lldap"
    ];

    services.traefik.dynamicConfigOptions.http = {
      routers.lldap = {
        entrypoints = "websecure";
        rule = "Host(`lldap.${config.networking.domain}`)";
        middlewares = [ "local-only" ];
        service = "lldap";
      };
      services.lldap.loadBalancer.servers = [{ url = "http://127.0.0.1:17170"; }];
    };

    # age.secrets.lldap-jwt-secret.file = ./.lldap-jwt-secret.age;

  };
}
