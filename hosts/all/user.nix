{ config, lib, pkgs, this, ... }: 

let

  inherit (lib) mkIf mkOption types;
  inherit (builtins) hasAttr filter;
  inherit (this.lib) mkAttrs;

  # Filter list of groups to only those which exist
  ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;

  # Return passed list if user is admin, else return empty list
  ifAdmin = user: list: if builtins.elem user this.admins then list else [];

  # public keys from the secrets dir
  keys = config.modules.secrets.keys.users.all;

  # agenix secrets combined secrets toggle
  secrets = config.age.secrets // { inherit (config.modules.secrets) enable; };

in {

  # Since we're using fish as our shell
  programs.fish.enable = true;

  # Add all users found in configurations/*/home/*
  users.users = ({
    # Create shared system users
    media = {
      isSystemUser = true;
      group = "media";
      uid = config.ids.uids.media;
    };
    photos = {
      isSystemUser = true;
      group = "photos";
      uid = config.ids.uids.photos;
    };
   } // mkAttrs this.users (user: { 
    isNormalUser = true;
    shell = pkgs.fish;
    hashedPasswordFile = mkIf (secrets.enable) secrets.password-hash.path;
    password = mkIf (!secrets.enable) "${user}";
    extraGroups = ifAdmin user ([ "wheel" ] ++ ifTheyExist [ "networkmanager" "podman" "docker" "media" "photos" "render" "video" ]);
    # openssh.authorizedKeys.keys = keys;
    openssh.authorizedKeys.keys = config.modules.secrets.keys.users."${user}";
  })); 

  # GIDs 900-909 are custom shared groups in my flake                                                                                                                                   
  # UID/GIDs 910-999 are custom system users/groups in my flake                                                                                                                         

  # Create secrets group
  ids.gids.secrets = 900;
  users.groups.secrets.gid = config.ids.gids.secrets;
                                                                                                                                                                                        
  # Create media user and group                                                                                                                                                                 
  ids.uids.media = 901;
  ids.gids.media = 901;                                                                                                                                                                 
  users.groups.media.gid = config.ids.gids.media;                                                                                                                                
                                                                                                                                                                                        
  # Create photos group      
  ids.uids.photos = 902;                                                                                                                                                              
  ids.gids.photos = 902;                                                                                                                                                                
  users.groups.photos.gid = config.ids.gids.photos;

}
