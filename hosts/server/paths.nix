{ lib, pkgs, config, ... }:
{
  imports = [ ../../modules/paths.nix ];
  my.paths = rec {
    data = "/media/naspool1/data";
    userData = "${data}/Users";
    systemData = "${data}/System";
    media = "/media/naspool1/media";
    mediaData = "${media}/.local";
    music = "${media}/Music";
    podcasts = "${media}/Podcasts";
  };
}

{ lib, pkgs, config, ... }:
let
  cfg = config.my.paths;
  types = lib.types;
in
{
  options.my.paths = lib.mkOption {
    type = types.attrsOf types.path;
    description = lib.mdDoc ''
      Path definitions to use in your own configuration.

      You could use the example like this for example:
      ```nix
      {
        subsonic.defaultMusicFolder = "${config.my.paths.media}/Music";
      }
      ```

      These options by themselves are a no-op. You have to use them yourself.
    '';
    default = { };
    example = {
      media = "/mnt/nas/media";
      persisted = "/persist";
    };
  };
}
