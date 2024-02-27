{ config, lib, this, ... }:
let

  cfg = config.paths;

  inherit (lib) mkOption types;

in {

  options.paths = mkOption {      
    type = types.attrsOf types.path;
    default = {};
  };

  config = {
    paths = rec {
      storage = "/mnt/storage";

      applications = "${storage}/applications";
      backup = "${storage}/backup";
      documents = "${storage}/documents";
      media = "${storage}/media";
      photos = "${storage}/photos";
    };

    file = {
      "${cfg.storage}" = { type = "dir"; mode = 775; };

      "${cfg.applications}" = { type = "dir"; mode = 755; };
      "${cfg.backup}" = { type = "dir"; mode = 755; };
      "${cfg.documents}" = { type = "dir"; mode = 755; };
      "${cfg.media}" = { 
        type = "dir"; mode = 775;
        user = config.users.users.media.uid; 
        group = config.users.groups.media.gid;
      };
      "${cfg.photos}" = { 
        type = "dir"; mode = 775;
        user = config.users.users.photos.uid; 
        group = config.users.groups.photos.gid;
      };
    };
  };

}

# { lib, pkgs, config, ... }:
# let
#   cfg = config.my.paths;
#   types = lib.types;
# in
# {
#   options.my.paths = lib.mkOption {
#     type = types.attrsOf types.path;
#     description = lib.mdDoc ''
#       Path definitions to use in your own configuration.

#       You could use the example like this for example:
#       ```nix
#       {
#         subsonic.defaultMusicFolder = "${config.my.paths.media}/Music";
#       }
#       ```

#       These options by themselves are a no-op. You have to use them yourself.
#     '';
#     default = { };
#     example = {
#       media = "/mnt/nas/media";
#       persisted = "/persist";
#     };
#   };
# }
