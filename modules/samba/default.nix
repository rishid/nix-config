# modules.samba.enable = true;
{ config, lib, pkgs, this, ... }:

let

  cfg = config.modules.samba;
  inherit (lib) mkIf mkBefore mkOption options types;
  inherit (builtins) toString;
  inherit (this.lib) extraGroups;

in {
  options.modules.samba = {
    enable = options.mkEnableOption "samba";
    shares = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    users.groups.samba-users = {};

    # Needed for Windows 10/11 clients
    services.samba-wsdd.enable = true; 

    services.samba = {
      enable = true;
      openFirewall = true;
      securityType = "user";
      extraConfig = ''
        min protocol = SMB2
        workgroup = WORKGROUP

        ea support = yes
        vfs objects = acl_xattr catia fruit streams_xattr
        fruit:metadata = stream
        fruit:model = MacSamba
        fruit:veto_appledouble = no
        fruit:posix_rename = yes
        fruit:zero_file_id = yes
        fruit:wipe_intentionally_left_blank_rfork = yes
        fruit:delete_empty_adfiles = yes
        fruit:nfs_aces = no

        browseable = yes
        guest ok = no
        guest account = nobody
        map to guest = bad user
        inherit acls = yes
        map acl inherit = yes
        valid users = @samba-users

        veto files = /._*/.DS_Store/
        delete veto files = yes
      '';
      shares = cfg.shares;
    };
  };
}
