# modules.sftp-server.enable = true;
{ config, lib, pkgs, this, ... }:

let  

  cfg = config.modules.sftp-server;
  inherit (lib) mkIf mkOption options types;

in {
  options.modules.sftp-server = {
    enable = options.mkEnableOption "sftp-server"; 

    jailRoot = mkOption {
      type = types.path;
      default = "/srv/sftp";
    };
  };

  config = mkIf cfg.enable {
    users.users.photo-backup = {        
      isSystemUser = true;
      createHome = false;
      group = "sftpusers";
      description = "Photo backup sftp only user";
      hashedPassword = "$6$jl9NVTVYisHSsKAy$ptc06ahjA2.U7bdSG6BInwbMEAj69aSkxXfolFjvDddmPzpUkgiZGqU4huz3fVTsnfdPXfyQt94fWPrUssNDq0";
      shell = null;
    };

    users.groups.sftpusers = { };

    # create the directories for each user
    systemd.tmpfiles.rules = [
      "d ${cfg.jailRoot} 0755 root root - -"
      "z ${cfg.jailRoot} 0755 root root - -"
      "d ${cfg.jailRoot}/photo-backup 0700 photo-backup nogroup - -"
      "z ${cfg.jailRoot}/photo-backup 0700 photo-backup nogroup - -"
    ];

    services.openssh = {
      allowSFTP = true;
      sftpServerExecutable = "internal-sftp";

  # ${config.users.users.sftp.home}
      extraConfig = ''      
        Match Group sftpusers
          ChrootDirectory ${cfg.jailRoot}
          ForceCommand internal-sftp
          AllowAgentForwarding no
          AllowTcpForwarding no
          # PermitTTY no
          # PermitTunnel no
          X11Forwarding no
          PasswordAuthentication yes
      '';
    }; 
  };
}
