# modules.virtualisation.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.virtualisation;
  inherit (lib) mkIf mkBefore mkOption options types;

in {

  options.modules.virtualisation.enable = options.mkEnableOption "virtualisation"; 

  config = mkIf cfg.enable {

    # Enable Docker and set to backend (over podman default)
    virtualisation = {
      docker.enable = true;
      docker.storageDriver = "overlay2";
      docker.autoPrune.enable = true;
      docker.autoPrune.dates = "quarterly";
      oci-containers.backend = "docker";
    };

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

  };

}
