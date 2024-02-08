{ config, ... }:
{
  services.postgresql = {
    ensureDatabases = [ "speedtest" ];

    ensureUsers = [{
      name = "speedtest";
      ensureDBOwnership = true;
    }];
  };

  virtualisation.oci-containers.containers.speedtest = {
    image = "ghcr.io/alexjustesen/speedtest-tracker:latest";
    autoStart = true;

    ports = [
      "8002:80"
    ];

    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "speedtest_config:/config"
      "/run/postgresql:/run/postgresql"
    ];

    environment = {
      PUID = "1000";
      PGID = "1000";
      DB_CONNECTION = "pgsql";
      DB_HOST = "/run/postgresql";
      DB_PORT = "5432";
      DB_DATABASE = "speedtest";
      DB_USERNAME = "speedtest";
      TZ = "America/New_York";
    };
  };
}
