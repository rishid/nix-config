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
          endpoint = "tcp://localhost:2375";
          exposedByDefault = false;
        };

        # Listen on port 80 and redirect to port 443
        entryPoints.web = {
          address = ":81";
          http.redirections.entrypoint.to = "websecure";
        };

        # Run everything on 443
        entryPoints.websecure = {
          address = ":444";
          # http.tls.certresolver = "resolver-dns";
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
        certificatesResolvers.resolver-dns.acme = {
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
        };

        middlewares.compress.compress = { };
        tls.options.default = {
          minVersion = "VersionTLS12";
          sniStrict = true;
        };

        # Set up wildcard domain certificates for both *.hostname.domain and *.local.domain
        http.routers = {
          traefik = {
            entrypoints = "websecure";
            rule = "Host(`traefik.${domain}`)";
            tls.certresolver = "resolver-dns";
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

    services.fail2ban.enable = true;

  };

}
