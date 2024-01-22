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

    # service
    virtualisation.oci-containers.containers."whoami" = with config.networking; {
      image = "${image}:${version}";

      labels = {
        "autoheal" = "true";
        "traefik.enable" = "true";
        "traefik.http.routers.whoami.rule" = "Host(`${cfg.hostName}`)";
        "traefik.http.routers.whoami.middlewares" = "authelia@file";        
        "traefik.http.routers.whoami.tls.certresolver" = "resolver-dns";
      };
    };

    # Enable reverse proxy
    modules.traefik.enable = true;

  }; 

}
