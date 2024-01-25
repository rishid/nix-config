{ pkgs, lib, config, this, ... }:

let 
  cfg = config.modules.msmtp;

  inherit (lib) mkIf mkOption options types strings mkBefore;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {

  options.modules.msmtp = {
    enable = options.mkEnableOption "msmtp";
  };

  config = mkIf cfg.enable {
    sops.secrets.gmail-password = {
      sopsFile = ./secret.sops.yaml;
      owner = "${config.deviceCfg.username}";
      group = "users";
    };

    programs.msmtp = {
      enable = true;
      accounts = {
        gmail = {
          auth = true;
          host = "smtp.gmail.com";
          port = 587;
          tls = true;
          tls_starttls = true;
          from = "budimanjojo@gmail.com";
          user = "budimanjojo";
          passwordeval = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.gmail-password.path}";
        };
      };
      extraConfig = ''
        account default: gmail
      '';
    };
  };
}
