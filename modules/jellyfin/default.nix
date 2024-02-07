# modules.jellyfin.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "jellyfin/jellyfin";
  version = "latest";
  port = 8096;

  cfg = config.modules.jellyfin;  
  inherit (lib) mkIf mkOption types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.jellyfin = {
    enable = lib.options.mkEnableOption "jellyfin"; 
    hostName = mkOption {
      type = types.str;
      default = "jellyfin.${config.networking.domain}";
      description = "FQDN for the Jellyfin instance";
    };
    configDir= mkOption {
      type = types.str; 
      default = "/var/lib/jellyfin"; 
    };
  };

  config = lib.mkIf cfg.enable {

    # Unused uid/gid snagged from this list:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
    ids.uids.jellyfin = lib.mkForce 924;
    ids.gids.jellyfin = lib.mkForce 924;

    users = {
      users = {

        jellyfin = {
          isSystemUser = true;
          group = "jellyfin";
          extraGroups = [ "media" "video" "render" ];
          description = "jellyfin daemon user";
          home = cfg.configDir;
          createHome = true;
          homeMode = "0755";
          uid = config.ids.uids.jellyfin;
        };

      # Add admins to the jellyfin group
      } // extraGroups this.admins [ "jellyfin" ];

      # Create group
      groups.jellyfin = {
        gid = config.ids.gids.jellyfin;
      };

    };

    backup.localPaths = [
      "${cfg.configDir}"
    ];

    # Enable vaapi on OS-level
    # nixpkgs.config.packageOverrides = pkgs: {
    #   vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
    # };
    # hardware.opengl = {
    #   enable = true;
    #   extraPackages = [
    #     pkgs.intel-media-driver
    #     pkgs.vaapiIntel
    #     pkgs.vaapiVdpau
    #     pkgs.libvdpau-va-gl
    #   ];
    # };

    # "-l=homepage.group=Media"
    #       "-l=homepage.name=Jellyfin"
    #       "-l=homepage.icon=jellyfin.svg"
    #       "-l=homepage.href=https://jellyfin.${vars.domainName}"
    #       "-l=homepage.description=Media player"
    #       "-l=homepage.widget.type=jellyfin"
    #       "-l=homepage.widget.key={{HOMEPAGE_FILE_JELLYFIN_KEY}}"
    #       "-l=homepage.widget.url=http://jellyfin:8096"
    #       "-l=homepage.widget.enableBlocks=true"
    
    # Override default hardening measure from NixOS
    # systemd.services.jellyfin.serviceConfig.PrivateDevices = lib.mkForce false;
    # systemd.services.jellyfin.serviceConfig.DeviceAllow = lib.mkForce ["/dev/dri/renderD128"];

    # Enable reverse proxy
    modules.traefik.enable = true;

    virtualisation.oci-containers.containers.jellyfin = {
      image = "${image}:${version}";
      user = "${toString config.ids.uids.jellyfin}:${toString config.ids.gids.jellyfin}";

      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${cfg.configDir}:/config"
        #"${cfg.mediaDir}:/data/media"
        "/dev/shm:/data/transcode"
      ];

      extraOptions = [
        "--pull=always"
        "--network=internal"
        "--group-add=303"
        "--device=/dev/dri:/dev/dri"
        # "--add-host=host.docker.internal:host-gateway"
      ];

      # ports = ["3890:3890"];
      
      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.jellyfin.entrypoints" = "websecure";
        # "traefik.http.routers.jellyfin.middlewares" = "authelia@file";
        "traefik.http.services.jellyfin.loadbalancer.server.port" = "${toString port}";

        "homepage.group" = "Media";
        "homepage.name" = "Jellyfin";
        "homepage.icon" = "jellyfin.svg";
        "homepage.href" = "https://${cfg.hostName}:444";
        "homepage.description" = "Media player";
        "homepage.widget.type" = "jellyfin";
        "homepage.widget.key" = "{{HOMEPAGE_FILE_JELLYFIN_KEY}}";
        "homepage.widget.url" = "http://jellyfin:${toString port}";
        "homepage.widget.enableBlocks" = "true";
        "homepage.widget.enableNowPlaying" = "true";
      };
    };

  };

}
