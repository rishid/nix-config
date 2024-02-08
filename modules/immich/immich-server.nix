{ config, lib, pkgs, ... }:

let

  cfg = config.modules.immich;
  inherit (lib) mkIf;

in {

  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    # Server back-end
    virtualisation.oci-containers.containers.immich-server = {
      image = "ghcr.io/immich-app/immich-server:v${cfg.version}";
      cmd = [ "start-server.sh" ];
      autoStart = false;

      # Run as immich user
      user = "${cfg.environment.PUID}:${cfg.environment.PGID}";

      # Environment variables
      environment = cfg.environment;

      # Map volumes to host
      volumes = [ 
        "/run/postgresql:/run/postgresql"
        "/run/redis-immich:/run/redis-immich"
      ] ++ [
        "${cfg.dataDir}:/usr/src/app/upload"
      ] ++ (if cfg.photosDir == "" then [] else [
        "${cfg.photosDir}:/usr/src/app/upload/library" 
      ]) ++ (if cfg.externalDir == "" then [] else [
        "${cfg.externalDir}:/external:ro" 
      ]);

      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.immich.entrypoints" = "websecure";
        "traefik.http.routers.immich.rule" = "Host(`${cfg.hostName}`)";
        "traefik.http.routers.immich.middlewares" = "authelia@file";
        # "traefik.http.services.sonarr.loadbalancer.server.port" = "${toString port}";

        "homepage.group" = "Media";
        "homepage.name" = "Immich";
        "homepage.icon" = "immich.svg";
        "homepage.href" = "https://${cfg.hostName}:444";
        "homepage.description" = "Photos";
        "homepage.widget.type" = "immich";
        "homepage.widget.key" = "{{HOMEPAGE_FILE_IMMICH_KEY}}";
        "homepage.widget.url" = "http://immich-server:3001";
      };

      extraOptions = [
        "--network=internal"
        # https://github.com/immich-app/immich/blob/main/docker/hwaccel.yml
        "--group-add=303"
        "--device=/dev/dri:/dev/dri" 
      ];
 
    };

    # ITSCGjl4bcfToAD6Ejs8ljetQ3u7vLc0WzX0iAiHk

    # Extend systemd service
    systemd.services.docker-immich-server = {
      requires = [ "immich.service" ];

      # Container will not stop gracefully, so kill it
      serviceConfig = {
        KillSignal = "SIGKILL";
        SuccessExitStatus = "0 SIGKILL";
      };

    };

  };

}
