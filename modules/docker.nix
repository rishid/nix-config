{ config, lib, pkgs, ... }:

# with lib;
# with lib.my;
let cfg = config.modules.services.docker;
    # configDir = config.dotfiles.configDir;
in {
  options.modules.services.docker = {
    enable = lib.mkEnableOption "Enable docker";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker-compose  
    ];

    # environment.variables.DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
    # environment.variables.MACHINE_STORAGE_PATH = "$XDG_DATA_HOME/docker/machine";

    users.users.rishi.extraGroups = [ "docker" ];

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
        autoPrune.dates = "quarterly";
        # listenOptions = [];
      };
    };
  };
}
