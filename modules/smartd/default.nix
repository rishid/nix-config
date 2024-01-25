# modules.smartd.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.smartd;

  inherit (lib) mkIf mkOption options types strings mkBefore;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.smartd = {
    enable = options.mkEnableOption "smartd";
  };

  config = mkIf cfg.enable {

    services.smartd =   
      let
        smartdNotify =
          pkgs.writeShellScript "smartd-notify" ''
            ${lib.getExe pkgs.curl} \
              -H 'Priority: urgent' \
              -H "Title: smartd failure: $SMARTD_DEVICE" \
              -H 'Tags: smartd' \
              -d "smartd: $SMARTD_FULLMESSAGE" \
              ntfy.sh/downtherabbithole
          '';
      in
      {
        enable = true;
        defaults.monitored = "-a -o on -S on -n standby,q -s (S/../.././01|L/../01/./03) -W 4,35,40 -M exec ${smartdNotify}";
        notifications = {
          # test = true;
          wall.enable = true;
        };
      };
  };
}
