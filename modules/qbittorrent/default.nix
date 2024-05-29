# modules.qbittorrent.enable = true;
{ config, lib, pkgs, this, ... }:

let

  # https://github.com/qdm12/gluetun
  image = "ghcr.io/qdm12/gluetun";      
  version = "latest";
  port = 9091;

  cfg = config.modules.qbittorrent;
  secrets = config.age.secrets;

  inherit (lib) mkIf mkOption options types strings mkBefore;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.qbittorrent = {
    enable = options.mkEnableOption "qbittorrent"; 
    hostName = mkOption {
      type = types.str;
      default = "torrent.${config.networking.domain}";
      description = "FQDN for the qbittorrent instance";
    };
    configDir = mkOption {
      type = types.path;
      default = "/var/lib/qbittorrent";
    };
  };

  # todo: look at auto adding to a homepage
  # https://github.com/nikitawootten/infra/blob/c56abade2ee7edfe96e8b50ed5d963bc6f43e928/hosts/hades/lab/homepage.nix#L80

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.qbittorrent = lib.mkForce 926;
    ids.gids.qbittorrent = lib.mkForce 926;

    users = {
      users = {

        # Add user to the qbittorrent group
        qbittorrent = {
          isSystemUser = true;
          group = "qbittorrent";
          extraGroups = [ "media" ];
          description = "qbittorrent daemon user";
          home = cfg.configDir;
          createHome = true;
          homeMode = "0775";
          uid = config.ids.uids.qbittorrent;
        };

      # Add admins to the qbittorrent group
      } // extraGroups this.admins [ "qbittorrent" ];

      # Create group
      groups.qbittorrent = {
        gid = config.ids.gids.qbittorrent;
      };

    };

    backup.localPaths = [
      "${cfg.configDir}"
    ];

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers = {
      gluetun = {
        image = "${image}:${version}";
        ports = [
          # "8888:8888/tcp" # HTTP proxy
          # "8388:8388/tcp" # Shadowsocks
          # "8388:8388/udp" # Shadowsocks
          # "8080:8080" # QBT UI Port
          "8000:8000"
        ];
        environmentFiles = [ secrets.transmission-ovpn.path ];
        environment = {
          TZ = "America/New_York";
          VPN_SERVICE_PROVIDER = "private internet access";
          SERVER_REGIONS = "Netherlands";
        };

        extraOptions = [
          "--pull=always"
          "--network=internal"
          "--cap-add=NET_ADMIN"
        ];

        labels = {
          "autoheal" = "true";
          "traefik.enable" = "true";
          "traefik.http.routers.qbittorrent.entrypoints" = "websecure";
          "traefik.http.routers.qbittorrent.rule" = "Host(`${cfg.hostName}`)";
          "traefik.http.routers.qbittorrent.middlewares" = "authelia@file";
          "traefik.http.services.qbittorrent.loadbalancer.server.port" = "8080";

          "homepage.group" = "Utils";
          "homepage.name" = "Gluetun";
          "homepage.icon" = "gluetun.svg";
          "homepage.href" = "https://${cfg.hostName}:444";
          "homepage.description" = "VPN killswitch";
          "homepage.widget.type" = "gluetun";
          "homepage.widget.url" = "http://gluetun:8000";
        };
        
      };

      qbittorrent = {
        image = "ghcr.io/onedr0p/qbittorrent:rolling";
        dependsOn = ["gluetun"];
        user = "${toString config.ids.uids.qbittorrent}:${toString config.ids.gids.media}";

        volumes = [
          "${cfg.configDir}:/config"
          "${config.paths.downloads}:/downloads"      
        ];

        extraOptions = [
          "--pull=always"
          "--network=container:gluetun"
          "--device=/dev/net/tun:/dev/net/tun"
        ];

        environment = {
          TZ = "America/New_York";
          QBITTORRENT__PORT = "8080";
          QBITTORRENT__BT_PORT = "50413";

          QBT_BitTorrent__Session__AddExtensionToIncompleteFiles = "true";
          QBT_BitTorrent__Session__IgnoreSlowTorrentsForQueueing = "true";
          QBT_BitTorrent__Session__MaxActiveDownloads = "10";
          QBT_BitTorrent__Session__MaxActiveTorrents = "25";
          QBT_BitTorrent__Session__MaxActiveUploads = "10";
          QBT_BitTorrent__Session__MaxConnections = "1000";
          QBT_BitTorrent__Session__MaxConnectionsPerTorrent = "200";
          QBT_BitTorrent__Session__MaxUploads = "50";
          QBT_BitTorrent__Session__MaxUploadsPerTorrent = "10";
          QBT_BitTorrent__Session__QueueingSystemEnabled = "true";
          QBT_BitTorrent__Session__SlowTorrentsDownloadRate = "5";
          QBT_BitTorrent__Session__SlowTorrentsUploadRate = "5";
          
          QBT_Preferences__Bittorrent__MaxUpload = "1000";
          QBT_Preferences__Bittorrent__MaxUploadsPerTorrent = "10";
          QBT_Preferences__Downloads__TempPath = "/downloads/incomplete/";

          QBT_Preferences__WebUI__AuthSubnetWhitelistEnabled = "true";
          QBT_Preferences__WebUI__AuthSubnetWhitelist = "172.19.0.0/16";          
        };

        labels = {
          "autoheal" = "true";

          "homepage.group" = "Arr";
          "homepage.name" = "qBittorrent";
          "homepage.icon" = "qbittorrent.svg";
          "homepage.href" = "https://${cfg.hostName}:444";
          "homepage.description" = "Torrent client";
          "homepage.widget.type" = "qbittorrent";
          "homepage.widget.url" = "http://gluetun:8080";
          "homepage.widget.username" = "admin";
          "homepage.widget.password" = "password";
        };
        
      };
      
      # labels = {
      #   "autoheal" = "true";
      #   "traefik.enable" = "true";
      #   #"traefik.http.routers.transmission.rule" = "Host(`${cfg.hostName}`) && PathPrefix(`/transmission`)";
      #   "traefik.http.routers.transmission.entrypoints" = "websecure";        
      #   "traefik.http.routers.transmission.rule" = "Host(`${cfg.hostName}`)";
      #   "traefik.http.routers.transmission.middlewares" = "authelia@file";
      #   "traefik.http.services.transmission.loadbalancer.server.port" = "${toString port}";

      #   "homepage.group" = "Arr";
      #   "homepage.name" = "Transmission";
      #   "homepage.icon" = "transmission.svg";
      #   "homepage.href" = "https://${cfg.hostName}:444";
      #   "homepage.description" = "Torrent downloader";
      #   "homepage.widget.type" = "transmission";
      #   "homepage.widget.username" = "username";
      #   "homepage.widget.password" = "password";        
      #   "homepage.widget.url" = "http://transmission-ovpn:${toString port}";
      #   "homepage.widget.rpcUrl" = "/transmission/";
      # };

      # extraOptions = [
      #   "--pull=always"
      #   "--network=internal"
      #   "--cap-add=NET_ADMIN"
      #   "--device=/dev/net/tun:/dev/net/tun"
        # "--dns=1.1.1.1"
        # "--dns=8.8.8.8"
        # "--no-healthcheck"
        # "--privileged"
        # "--shm-size=67108864"
        # "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
      # ];
    };

    # TODO: I think transmission requires, something to review
    # networking.enableIPv6 = false;

  };

}
