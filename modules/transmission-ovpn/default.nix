# modules.transmission-ovpn.enable = true;
{ config, lib, pkgs, this, ... }:

let

  # https://github.com/haugene/docker-transmission-openvpn
  image = "docker.io/haugene/transmission-openvpn";      
  version = "latest";
  port = 9091;

  cfg = config.modules.transmission-ovpn;
  secrets = config.age.secrets;

  inherit (lib) mkIf mkOption options types strings mkBefore;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.transmission-ovpn = {

    enable = options.mkEnableOption "transmission-ovpn"; 

    hostName = mkOption {
      type = types.str;
      default = "trans.${config.networking.domain}";
      description = "FQDN for the Transmission instance";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/transmission-ovpn";
    };

  };

  # todo: look at auto adding to a homepage
  # https://github.com/nikitawootten/infra/blob/c56abade2ee7edfe96e8b50ed5d963bc6f43e928/hosts/hades/lab/homepage.nix#L80

  config = mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.transmission = lib.mkForce 914;
    ids.gids.transmission = lib.mkForce 914;

    users = {
      users = {

        # Add user to the transmission group
        transmission = {
          isSystemUser = true;
          group = "transmission";
          description = "transmission daemon user";
          home = cfg.dataDir;
          uid = config.ids.uids.transmission;
        };

      # Add admins to the transmission group
      } // extraGroups this.admins [ "transmission" ];

      # Create group
      groups.transmission = {
        gid = config.ids.gids.transmission;
      };

    };

    # Ensure data directory exists
    file."${cfg.dataDir}" = {
      type = "dir"; mode = 775; 
      user = config.ids.uids.transmission; 
      group = config.ids.gids.transmission;
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.transmission-ovpn = {
      image = "${image}:${version}";
      hostname = "transmission-ovpn";

      # Run as transmission user
      # user = with config.ids; "${toString uids.transmission}:${toString gids.transmission}";

      environmentFiles = [ secrets.transmission-ovpn.path ];

      environment = {
        PUID = "${toString config.ids.uids.transmission}";
        PGID = "${toString config.ids.gids.transmission}";
        OPENVPN_PROVIDER= "PIA";
        OPENVPN_CONFIG= "switzerland";
        # Set in secrets env file
        # OPENVPN_USERNAME=
        # OPENVPN_PASSWORD=
        OPENVPN_OPTS= "--inactive 3600 --ping 10 --ping-exit 30";
        OVERRIDE_DNS_1= "1.1.1.1";
        OVERRIDE_DNS_2= "8.8.8.8";
        LOCAL_NETWORK= "192.168.1.0/24";
        CREATE_TUN_DEVICE = "false";
        LOG_TO_STDOUT= "true";

        #TRANSMISSION_BIND_ADDRESS_IPV4= "0.0.0.0";
        #TRANSMISSION_BIND_ADDRESS_IPV6= "::"
        #TRANSMISSION_BLOCKLIST_ENABLED= "false";
        #TRANSMISSION_BLOCKLIST_URL= "http://www.example.com/blocklist";
        #TRANSMISSION_CACHE_SIZE_MB= "4";
        #TRANSMISSION_DHT_ENABLED= "true";
        #TRANSMISSION_DOWNLOAD_DIR= "/data/completed";
        TRANSMISSION_DOWNLOAD_QUEUE_ENABLED= "true";
        TRANSMISSION_DOWNLOAD_QUEUE_SIZE= "5";
        #TRANSMISSION_ENCRYPTION= "1";
        TRANSMISSION_IDLE_SEEDING_LIMIT= "360";
        TRANSMISSION_IDLE_SEEDING_LIMIT_ENABLED= "false";
        #TRANSMISSION_INCOMPLETE_DIR= "/data/incomplete";
        #TRANSMISSION_INCOMPLETE_DIR_ENABLED= "true";
        #TRANSMISSION_LPD_ENABLED= "false";
        #TRANSMISSION_MESSAGE_LEVEL= "2";
        #TRANSMISSION_PEER_CONGESTION_ALGORITHM=
        #TRANSMISSION_PEER_ID_TTL_HOURS= "6";
        TRANSMISSION_PEER_LIMIT_GLOBAL= "1000";
        TRANSMISSION_PEER_LIMIT_PER_TORRENT= "300";
        #TRANSMISSION_PEER_PORT= "51413";
        #TRANSMISSION_PEER_PORT_RANDOM_HIGH= "65535";
        #TRANSMISSION_PEER_PORT_RANDOM_LOW= "49152";
        #TRANSMISSION_PEER_PORT_RANDOM_ON_START= "false";
        #TRANSMISSION_PEER_SOCKET_TOS= "default";
        #TRANSMISSION_PEX_ENABLED= "true";
        #TRANSMISSION_PORT_FORWARDING_ENABLED= "false";
        #TRANSMISSION_PREALLOCATION= "1";
        #TRANSMISSION_PREFETCH_ENABLED= "1";
        #TRANSMISSION_QUEUE_STALLED_ENABLED= "true";
        #TRANSMISSION_QUEUE_STALLED_MINUTES= "30";
        TRANSMISSION_RATIO_LIMIT= "2";
        TRANSMISSION_RATIO_LIMIT_ENABLED= "true";
        #TRANSMISSION_RENAME_PARTIAL_FILES= "true";
        #TRANSMISSION_RPC_AUTHENTICATION_REQUIRED= "false";
        #TRANSMISSION_RPC_BIND_ADDRESS= "0.0.0.0";
        #TRANSMISSION_RPC_ENABLED= "true";
        TRANSMISSION_RPC_PASSWORD= "password";
        #TRANSMISSION_RPC_PORT= "9091";
        TRANSMISSION_RPC_URL= "/transmission/";
        #TRANSMISSION_RPC_USERNAME= "username";
        #TRANSMISSION_RPC_WHITELIST= "127.0.0.1";
        #TRANSMISSION_RPC_WHITELIST_ENABLED= "false";
        #TRANSMISSION_SCRAPE_PAUSED_TORRENTS_ENABLED= "true";
        #TRANSMISSION_SCRIPT_TORRENT_DONE_ENABLED= "true";
        #TRANSMISSION_SCRIPT_TORRENT_DONE_FILENAME= "/etc/transmission_unrar.sh";
        TRANSMISSION_SEED_QUEUE_ENABLED= "true";
        TRANSMISSION_SEED_QUEUE_SIZE= "20";
        #TRANSMISSION_SPEED_LIMIT_DOWN= "100";
        #TRANSMISSION_SPEED_LIMIT_DOWN_ENABLED= "false";
        #TRANSMISSION_SPEED_LIMIT_UP= "500";
        TRANSMISSION_SPEED_LIMIT_UP_ENABLED= "false";
        #TRANSMISSION_START_ADDED_TORRENTS= "true";
        TRANSMISSION_TRASH_ORIGINAL_TORRENT_FILES= "true";
        #TRANSMISSION_UMASK= "2";
        TRANSMISSION_UPLOAD_SLOTS_PER_TORRENT= "50";
        #TRANSMISSION_UTP_ENABLED= "true";
        TRANSMISSION_WATCH_DIR= "/data/watch";
        TRANSMISSION_WATCH_DIR_ENABLED= "true";
        #TRANSMISSION_HOME= "/data/transmission-home";
      };

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.dataDir}:/data"
        # "/mnt/media:/storage:rw"
        # "/var/volumes/transmission/config:/config:rw"
        # "/var/volumes/transmission/scripts:/scripts:rw"
      #   "${config.lib.lab.mkConfigDir "transmission-ovpn"}/:/config"
      #   "${config.personal.lab.media.media-dir}/torrents/:/data"
      ];
      ports = [
        "9091:9091/tcp"
      ];
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        #"traefik.http.routers.transmission.rule" = "Host(`${cfg.hostName}`) && PathPrefix(`/transmission`)";
        "traefik.http.routers.transmission.rule" = "Host(`${cfg.hostName}`)";
        # "traefik.http.routers.transmission.middlewares" = "chain-authelia@file";        
        "traefik.http.routers.transmission.tls.certresolver" = "letsencrypt";
        "traefik.http.services.transmission.loadbalancer.server.port" = "${toString port}";
      };

      # Traefik labels
      # TODO: should switch to `labels` format
      # consider creating mkTraefikLabels
      # https://github.com/nikitawootten/infra/blob/c56abade2ee7edfe96e8b50ed5d963bc6f43e928/hosts/hades/lab/infra/traefik.nix#L95
      extraOptions = [
        "--pull=always"
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
        "--dns=1.1.1.1"
        "--dns=8.8.8.8"
        "--no-healthcheck"
        "--privileged"
        "--shm-size=67108864"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
      ];
    };

    # TODO: I think transmission requires, something to review
    networking.enableIPv6 = false;

    # Extend systemd service
    # systemd.services.docker-silverbullet = {
    #   after = [ "traefik.service" ];
    #   requires = [ "traefik.service" ];
    #   preStart = with config.virtualisation.oci-containers.containers; ''
    #     docker pull ${silverbullet.image};
    #   '';
    # };

  };

}
