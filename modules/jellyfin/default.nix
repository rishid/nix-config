# modules.jellyfin.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.jellyfin;
  port = "8096"; 
  inherit (lib) mkIf mkOption types;

in {

  options.modules.jellyfin = {
    enable = lib.options.mkEnableOption "jellyfin"; 
    hostName = mkOption {
      type = types.str;
      default = "jellyfin.${config.networking.domain}";
      description = "FQDN for the Jellyfin instance";
    };
  };

  config = lib.mkIf cfg.enable {

    services.jellyfin = {
      enable = true;
      # openFirewall = true;
    };

    users.groups.media.members = [ config.services.jellyfin.user ];

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

    # for hardware acceleration
    users.users.${config.services.jellyfin.user}.extraGroups = [ "video" "render" ];
    
    # Override default hardening measure from NixOS
    systemd.services.jellyfin.serviceConfig.PrivateDevices = lib.mkForce false;
    systemd.services.jellyfin.serviceConfig.DeviceAllow = lib.mkForce ["/dev/dri/renderD128"];

    # Enable reverse proxy
    modules.traefik.enable = true;

    services.traefik.dynamicConfigOptions.http = {
      routers.jellyfin = {
        entrypoints = "websecure";
        rule = "Host(`${cfg.hostName}`)";
        tls.certresolver = "resolver-dns";
        # middlewares = "local@file";
        service = "jellyfin";
      };
      services.jellyfin.loadBalancer.servers = [{ url = "http://127.0.0.1:${port}"; }];
    };

  };

}
