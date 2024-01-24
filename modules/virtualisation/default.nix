# modules.virtualisation.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.virtualisation;
  inherit (lib) mkIf mkBefore mkOption options types;

in {

  options.modules.virtualisation.enable = options.mkEnableOption "virtualisation"; 

  config = mkIf cfg.enable {

    virtualisation = {     

      oci-containers.backend = "docker";
      docker = {
        enable = true;
        # daemon.settings = {
        #   features = { buildkit = true; };
        # };
        storageDriver = "overlay2";
        autoPrune.enable = true;
        autoPrune.dates = "quarterly";
      };

      # oci-containers.backend = lib.mkForce "podman";
      # podman = {
      #   enable = true;
      #   dockerSocket.enable = true;
      #   dockerCompat = true;
      #   defaultNetwork.settings.dns_enabled = true;
      # };
      # containers.registries.search = [
      #   "docker.io" "gcr.io" "quay.io"
      # ];
      # containers.storage.settings = {
      #   storage = {
      #     driver = "overlay2";
      #     graphroot = "/var/lib/containers/storage";
      #     runroot = "/run/containers/storage";
      #   };
      # };
    };

    system.activationScripts.mkCoderNet = ''
    ${pkgs.docker}/bin/docker network create internal &2>/dev/null || true
  '';

    # Docker proxy for read-only container information
    virtualisation.oci-containers.containers."dockerproxy" = {
      image = "ghcr.io/tecnativa/docker-socket-proxy:edge";
      environment = {
        CONTAINERS = "1";
        IMAGES = "0";
        POST = "0";
        LOG_LEVEL = "debug";
      };
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        # "/run/podman/podman.sock:/var/run/docker.sock:rw"
      ];
      ports = [
        "2375:2375/tcp"
      ];
      # log-driver = "journald";
      extraOptions = [
        "--health-cmd=/bin/sh -c 'wget --no-verbose --spider --no-check-certificate http://127.0.0.1:2375/version || exit 1'"
        "--health-interval=10s"
        "--health-retries=10"
        "--health-timeout=5s"
        # "--network-alias=dockerproxy"
        # "--network=socket-proxy"
      ];    
    };

    # systemd.services."docker-dockerproxy" = {
    #   serviceConfig = {
    #     Restart = lib.mkOverride 500 "always";
    #   };
    #   after = [
    #     "podman-network-socket-proxy.service"
    #     "podman.socket"
    #   ];
    #   requires = [
    #     "podman-network-socket-proxy.service"
    #     "podman.socket"
    #   ];
    #   partOf = [
    #     "podman-compose-infra-root.target"
    #   ];
    #   wantedBy = [
    #     "podman-compose-infra-root.target"
    #   ];
    # };    

    # systemd.services.containers-network = with config.virtualisation.oci-containers; {
    #   serviceConfig.Type = "oneshot";
    #   wantedBy = [ "${backend}-traefik.service" "${backend}-homepage.service" "${backend}-portainer.service" "${backend}-vaultwarden.service" "${backend}-syncthing.service" ];
    #   script = ''
    #     ${pkgs.docker}/bin/${backend} network exists containers-network || \
    #     ${pkgs.docker}/bin/${backend} network create containers-network
    #     '';
    # };

  };

}
