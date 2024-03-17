{ config, lib, ... }:
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
      downloads = "/srv/downloads";
      media = "${storage}/media";
      photos = "${storage}/photos";
    };

    file = {
      "${cfg.storage}" = { type = "dir"; mode = 775; };

      "${cfg.applications}" = { type = "dir"; mode = 755; };
      "${cfg.backup}" = { type = "dir"; mode = 755; };
      "${cfg.documents}" = { type = "dir"; mode = 755; };
      "${cfg.downloads}" = { 
        type = "dir"; mode = 775;
        user = config.users.users.media.uid; 
        group = config.users.groups.media.gid;
      };
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
