# modules.traefik.enable = true;
{ config, lib, pkgs, this, ... }:

let
  cfg = config.modules.traefik;
  secrets = config.age.secrets;
  inherit (lib) mkIf options;

in {

  options.modules.traefik.enable = options.mkEnableOption "traefik"; 

  config = mkIf cfg.enable {

    # agenix
    users.users.traefik.extraGroups = [ "secrets" ]; 

    # Import the env file containing the CloudFlare token for cert renewal
    systemd.services.traefik = {
      serviceConfig.EnvironmentFile = [ secrets.traefik-env.path ];
    };

    modules.virtualisation.enable = true;

    services.traefik = with config.networking; {

      enable = true;

      # Required so traefik is permitted to watch docker events
      group = "docker"; 

      # Static configuration
      staticConfigOptions = {

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        api.dashboard = true;
        log.level = "DEBUG";

        experimental.http3 = true;

        accessLog = {
          filePath = "/var/lib/traefik/access.json";
          format = "json";
          fields.headers.defaultMode = "keep";
          bufferingSize = 100;
        };

        # Allow backend services to have self-signed certs
        serversTransport.insecureSkipVerify = true;

        # Watch docker events and discover services
        providers.docker = {
          # endpoint = "unix:///var/run/docker.sock";
          endpoint = "tcp://127.0.0.1:2375";
          exposedByDefault = false;
          defaultRule = "Host(`{{ normalize .Name }}.${config.networking.domain}`)";
          # network = "proxy";
        };

        # Listen on port 80 and redirect to port 443
        entryPoints.web = {
          address = ":81";
          http.redirections.entrypoint.to = "websecure";
        };

        # Run everything on 443
        entryPoints.websecure = {
          address = ":444";
          http = {
            tls = {
              certresolver = "letsencrypt";
              domains.main = "${config.networking.domain}";
              domains.sans = "*.${config.networking.domain}";
            };
          };
          # http.tls.certresolver = "letsencrypt";
          http3 = { };
        };

        # entryPoints = {
        #   jellyfin = {
        #     address = ":8096/tcp";
        #   };
        #   jellyfin-tls = {
        #     address = ":8920/tcp";
        #   };
        #   transmission-dht-tcp = {
        #     address = ":51413/tcp";
        #   };
        #   transmission-dht-udp = {
        #     address = ":51413/udp";
        #   };
        # };

        # Let's Encrypt will check CloudFlare's DNS
        certificatesResolvers.letsencrypt.acme = {
          dnsChallenge.provider = "cloudflare";
          email = "${hostName}@${domain}";
          keyType = "EC256";
          storage = "${config.services.traefik.dataDir}/acme.json";
        };
      };

      # Dynamic configuration
      dynamicConfigOptions = {

        # http.middlewares = {

        #   # Basic Authentication is available. User/passwords are encrypted by agenix.
        #   # login.basicAuth.usersFile = secrets.basic-auth.path;

        #   # Whitelist local network and VPN addresses
        #   local.ipWhiteList.sourceRange = [ 
        #     "127.0.0.1/32"   # local host
        #     "192.168.0.0/16" # local network
        #     "10.0.0.0/8"     # local network
        #     "172.16.0.0/12"  # docker network
        #     "100.64.0.0/10"  # vpn network
        #   ];

        # };

        http.middlewares = {
            authelia = {
              # Forward requests w/ middlewares=authelia@file to authelia.
              forwardAuth = {
                # address = cfg.autheliaUrl;
                address = "http://localhost:9092/api/verify?rd=https://auth.dhupar.xyz:444/";
              trustForwardHeader = true;
                authResponseHeaders = [
                  "Remote-User"
                  "Remote-Name"
                  "Remote-Email"
                  "Remote-Groups"
                ];
              };
            };
            authelia-basic = {
              # Forward requests w/ middlewares=authelia@file to authelia.
              forwardAuth = {
                address = "http://localhost:9092/api/verify?auth=basic";
                trustForwardHeader = true;
                authResponseHeaders = [
                  "Remote-User"
                  "Remote-Name"
                  "Remote-Email"
                  "Remote-Groups"
                ];
              };
            };
            # auth-headers = {
            #   browserXssFilter = true;
            #   contentTypeNosniff = true;
            #   forceSTSHeader = true;
            #   frameDeny = true;
            #   sslHost = domain;
            #   sslRedirect = true;
            #   stsIncludeSubdomains = true;
            #   stsPreload = true;
            #   stsSeconds = 315360000;
            # };
        };

        middlewares.compress.compress = { };
        tls.options.default = {
          minVersion = "VersionTLS13";
          sniStrict = true;
        };

        # Set up wildcard domain certificates for both *.hostname.domain and *.local.domain
        http.routers = {
          traefik = {
            entrypoints = "websecure";
            rule = "Host(`traefik.${domain}`)";
            tls.certresolver = "letsencrypt";
            tls.domains = [{
              main = "${domain}"; 
              sans = "*.${domain}"; 
            }];
            # middlewares = "local@file";
            service = "api@internal";
          };
          
        };

      };
    };

    #services.logrotate = {
    #  enable = true;
    #  paths.traefik = {
    #    enable = true;
    #    path = "/var/log/traefik/access.*";
    #    user = config.systemd.services.traefik.serviceConfig.User;
    #    group = config.systemd.services.traefik.serviceConfig.Group;
    #    frequency = "daily";
    #    keep = 16;
    #  };
    #};    

    # Open up the firewall for http and https
    networking.firewall.allowedTCPPorts = [ 80 81 443 444 ];

    # services.fail2ban.enable = true;

  };

}

# references:
# fn ideas: https://github.com/Helyosis/nix-config/blob/7a1a6b110930a9274ff46467ade0da26e28db2f2/hosts/server/traefik.nix#L46
# more fn: https://github.com/nikitawootten/infra/blob/8f827d78ea1cd02c73e10c521b4ad34d303f9176/hosts/hades/lab/infra/traefik.nix#L59
