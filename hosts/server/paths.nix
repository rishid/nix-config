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
