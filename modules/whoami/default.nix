# modules.whoami.enable = true;
{ inputs, config, pkgs, lib, ... }:
  
let 
  image = "traefik/whoami";
  version = "latest";

  cfg = config.modules.whoami;
  
  inherit (lib) mkIf mkOption options types;

in {

  options.modules.whoami = {
    enable = lib.options.mkEnableOption "whoami"; 

    hostName = mkOption {
      type = types.str; 
      default = "whoami.${config.networking.domain}";
      description = "FQDN for the whoami instance";
    }; 
  };
  
  config = mkIf cfg.enable {

    # Enable reverse proxy
    modules.traefik.enable = true;

    # service
    virtualisation.oci-containers.containers.whoami = {
      image = "${image}:${version}";

      extraOptions = [
        "--pull=always"
        "--network=internal"
      ];

      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.whoami.entrypoints" = "websecure";
        "traefik.http.routers.whoami.rule" = "Host(`${cfg.hostName}`)";
      };
    };

  }; 

}
