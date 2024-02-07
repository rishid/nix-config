{ config, lib, pkgs, this, ... }:

let
  cfg = config.modules.authelia;
  
  inherit (lib) mkIf mkOption mkAfter mkBefore options types strings;
  inherit (builtins) toString;
  # inherit (lib.strings) toInt;
  inherit (this.lib) extraGroups ls;
  
  domain = "auth.${config.networking.domain}";
  port = 9092; #default 9091 is being used by transmissions
  ldapHost = "localhost";
  ldapPort = config.services.lldap.settings.ldap_port;
  redis = config.services.redis.servers.authelia-main;

  # mkWebfinger = v:
  #   pkgs.writeTextDir (lib.escapeURL v.subject) (lib.generators.toJSON { } v);
  # webfingerRoot = pkgs.symlinkJoin {
  #   name = "felschr.com-webfinger";
  #   paths = builtins.map mkWebfinger [{
  #     subject = "acct:me@felschr.com";
  #     links = [{
  #       rel = "http://openid.net/specs/connect/1.0/issuer";
  #       href = "https://auth.felschr.com";
  #     }];
  #   }];
  # };

  # smtpAccount = config.programs.msmtp.accounts.default;
in {

  imports = ls ./.;

  options.modules.authelia = {
    enable = options.mkEnableOption "authelia";
  };

  # age.secrets.authelia-jwt = {
  #   file = ../secrets/authelia/jwt.age;
  #   owner = cfg.user;
  # };
  # age.secrets.authelia-session = {
  #   file = ../secrets/authelia/session.age;
  #   owner = cfg.user;
  # };
  # age.secrets.authelia-storage = {
  #   file = ../secrets/authelia/storage.age;
  #   owner = cfg.user;
  # };
  # age.secrets.authelia-oidc-hmac = {
  #   file = ../secrets/authelia/oidc-hmac.age;
  #   owner = cfg.user;
  # };
  # age.secrets.authelia-oidc-issuer = {
  #   file = ../secrets/authelia/oidc-issuer.age;
  #   owner = cfg.user;
  # };

  config = mkIf cfg.enable (let
    stateDirectory = "/var/lib/authelia-main";
    usersConfig = "${stateDirectory}/users.yaml";
    clientsConfig = "${stateDirectory}/clients.yaml";
  in {

    services.authelia.instances.main = {
      enable = true;

      secrets = {
        jwtSecretFile = config.age.secrets.authelia-jwt.path;
        storageEncryptionKeyFile = config.age.secrets.authelia-storage.path;
        sessionSecretFile = config.age.secrets.authelia-session.path;
        oidcHmacSecretFile = config.age.secrets.authelia-oidc-hmac.path;
        oidcIssuerPrivateKeyFile = config.age.secrets.authelia-oidc-issuer.path;
      };
      environmentVariables = {
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = toString config.age.secrets.lldap-user-password.path;
      #   AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets.smtp.path;
      };
      settings = {
        theme = "auto";
        log.level = "debug";

        server = {
          host = "0.0.0.0";
          inherit port;
        };

        # default_2fa_method = "totp";
        # default_redirection_url = "https://${domain}";

        authentication_backend = {
          # reference: https://github.com/lldap/lldap/blob/main/example_configs/authelia_config.yml
          password_reset.disable = false;
          refresh_interval = "5m";
          ldap = {
            implementation = "custom";
            url = "ldap://${ldapHost}:${toString ldapPort}";
            timeout = "5s";
            start_tls = false;
            base_dn = "dc=dhupar,dc=xyz";
            username_attribute = "uid";
            additional_users_dn = "ou=people";
            # Sign in with username or email.
            users_filter = "(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))";
            additional_groups_dn = "ou=groups";
            groups_filter = "(member={dn})";
            group_name_attribute = "cn";
            mail_attribute = "mail";
            display_name_attribute = "displayName";
            user = "uid=admin,ou=people,dc=dhupar,dc=xyz";
            # password = "password";
          };
        };
        totp = {
          disable = false;
          issuer = "auth.dhupar.xyz:444";          
          algorithm = "sha1";
          digits = 6;
          period = 30;
          skew = 1;
          secret_size = 32;
        };
        regulation = {
          max_retries = 3;
          find_time = "5m";
          ban_time = "15m";
        };

        access_control = {
          default_policy = "deny";
          networks = [
            {
              name = "internal";
              networks = [ "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/18" ];
            }
          ];
          rules = [
            {
              domain = [ "whoami.dhupar.xyz" ];
              policy = "bypass";
            }
            {
              domain = [ "auth.dhupar.xyz" ];
              policy = "bypass";
              resources = [
                "^/api/.*"
              ];
            }
            {
              domain = [ "*.dhupar.xyz" "dhupar.xyz" ];
              policy = "one_factor";
            }
          ];
        };
        session = {
          domain = "dhupar.xyz";
          redis = {
            host = redis.unixSocket;
            port = 0;
          };
        };
        storage.local = {
          path = "/var/lib/authelia-main/db.sqlite3";
        };
        # storage.postgres = {
        #   host = "/run/postgresql";
        #   inherit (config.services.postgresql) port;
        #   username = cfg.user;
        #   database = cfg.user;
        #   # password not used since it uses peer auth
        #   password = "dummy";
        # };

        notifier.filesystem = {
          filename = "/var/lib/authelia-main/notif.txt";
        };
        # notifier.smtp = {
        #   inherit (smtpAccount) host port;
        #   username = smtpAccount.user;
        #   sender = smtpAccount.from;
        # };
        identity_providers.oidc.clients = [
          {
            id = "Immich";
            description = "High performance self-hosted photo and video backup solution";
            authorization_policy = "one_factor";
            redirect_uris = [
              "app.immich:/"
              "https://immich.dhupar.xyz:444/api/oauth/mobile-redirect"
              "http://immich.dhupar.xyz:444/auth/login"
              "http://immich.dhupar.xyz:444/user-settings"
              "https://immich.dhupar.xyz:444/auth/login"
              "https://immich.dhupar.xyz:444/user-settings"
              "http://localhost:2283/auth/login"
              "http://localhost:2283/user-settings"
              "http://192.168.0.200:2283/auth/login"
              "http://192.168.0.200:2283/user-settings"
            ];
            secret = "$argon2id$v=19$m=65536,t=3,p=4$/zOkCrAwcIxAs9JeVynhuA$QGdKXHogOWnzIa1gKqvj8V3p5jBRdwtXMp9sEx3lihE";
          }
        #   {
        #     id = "miniflux";
        #     description = "Miniflux RSS";
        #     secret =
        #       "$pbkdf2-sha512$310000$uDoutefLT0wyfye.kBEyZw$tX7nwcRVo0LpPPS63Oh9MIeOLkdPRnXX/0JBwMd.aitFIxKDxU.rlywn/WqLVgpIllyFttMl5OnZzjMTbGKZ0A";
        #     redirect_uris = [ "https://news.felschr.com/oauth2/oidc/callback" ];
        #     scopes = [ "openid" "email" "profile" ];
        #   }
        #   {
        #     id = "tailscale";
        #     description = "Tailscale";
        #     # The digest of "insecure_secret"
        #     secret =
        #       "$pbkdf2-sha512$310000$c8p78n7pUMln0jzvd4aK4Q$JNRBzwAo0ek5qKn50cFzzvE9RXV88h1wJn5KGiHrD0YKtZaR/nCb2CJPOsKaPK0hjf.9yHxzQGZziziccp6Yng";
        #     redirect_uris = [ "https://login.tailscale.com/a/oauth_response" ];
        #     scopes = [ "openid" "email" "profile" ];
        #   }
        #   {
        #     id = "jellyfin";
        #     description = "Jellyfin";
        #     secret =
        #       "$pbkdf2-sha512$310000$X7amOzLsURvZSwdLmSstlQ$/WK4lZ9KvEEuotOxUJkeTo0ZAa.rD7VVdkAPFcUQmr2WzkCXmXXJbYYy7vx0hc4nqLgBVeo8q/71R3rvfl9BFQ";
        #     redirect_uris =
        #       [ "https://media.felschr.com/sso/OID/redirect/Authelia" ];
        #     scopes = [ "openid" "email" "profile" ];
        #   }
        ];
      };
    };

    users.users.authelia-main.extraGroups = [ "secrets" ]; 

    # systemd.services.authelia.requires = [ "postgresql.service" "lldap.service" ];
    # systemd.services.authelia.after = [ "postgresql.service" "lldap.service" ];
    systemd.services.authelia-main.requires = [ "lldap.service" ];
    systemd.services.authelia-main.after = [ "lldap.service" ];

    # services.postgresql = {
    #   enable = true;
    #   ensureDatabases = [ cfg.user ];
    #   ensureUsers = [{
    #     name = cfg.user;
    #     ensurePermissions."DATABASE \"${cfg.user}\"" = "ALL PRIVILEGES";
    #   }];
    # };

    services.redis.servers.authelia-main = {
      enable = true;
      port = 31641;
      user = "authelia-main";
      # inherit (cfg) user;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Traefik proxy
    services.traefik.dynamicConfigOptions.http = {
      routers.authelia = {
        entrypoints = "websecure";
        rule = "Host(`${domain}`)";
        tls.certresolver = "letsencrypt";
        # middlewares = "local@file";
        service = "authelia";
      };
      services.authelia.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString port}"; }];
    };

    # services.nginx.virtualHosts.${domain} = {
    #   enableACME = true;
    #   forceSSL = true;
    #   locations."/".proxyPass = "http://[::1]:${toString port}";
    # };

    # services.nginx.virtualHosts."felschr.com" = {
    #   enableACME = true;
    #   forceSSL = true;
    #   locations."/.well-known/webfinger" = {
    #     root = webfingerRoot;
    #     extraConfig = ''
    #       add_header Access-Control-Allow-Origin "*";
    #       default_type "application/jrd+json";
    #       types { application/jrd+json json; }
    #       if ($arg_resource) {
    #         rewrite ^(.*)$ /$arg_resource break;
    #       }
    #       return 400;
    #     '';
    #   };
    # };

    # users.users.${cfg.user}.extraGroups = [ "smtp" "ldap" ];
  });
}
