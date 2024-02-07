# modules.ddns.enable = true;
{ config, lib, pkgs, ... }:

let

  cfg = config.modules.ddns;
  secrets = config.age.secrets;
  inherit (lib) mkIf;

in {

  options.modules.ddns = {
    enable = lib.options.mkEnableOption "ddns"; 
  };

  config = mkIf cfg.enable {

    # Create DNS record of this machine's public IP
    # ddns.mymachine.mydomain.org -> 184.65.200.230 
    systemd.services."ddns" = {
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = secrets.cloudflare-env.path;
      };
      environment = with config.networking; {
        FQDNS = "dhupar.xyz;*.dhupar.xyz";
      };
      path = with pkgs; [ coreutils dig httpie inetutils jq ];
      script = builtins.readFile ./ddns.sh;
    };

    systemd.timers."ddns" = {
      wantedBy = [ "timers.target" ];
      partOf = [ "ddns.service" ];
      timerConfig = {
        OnCalendar = "*:0/15";
        Unit = "ddns.service";
      };
    };

  };

}
