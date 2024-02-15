# modules.dozzle.enable = true;
{ config, lib, pkgs, this, ... }:

let

  image = "amir20/dozzle";
  version = "latest";

  cfg = config.modules.dozzle;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {
  
  options.modules.dozzle = {
    enable = options.mkEnableOption "dozzle"; 
    hostName = mkOption {
      type = types.str; 
      default = "dozzle.${config.networking.domain}";
      description = "FQDN for the dozzle instance";
    };
    configDir= mkOption {
      type = types.str; 
      default = "/var/lib/dozzle"; 
    };
  };

  config = mkIf cfg.enable {

};
