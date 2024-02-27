{ config, this, ... }: let
  rootStoragePath = "/mnt/storage";
  
in {

  host = "server"; 
  config.modules.secrets.enable = true;
  
  applicationsPath = "${rootStoragePath}/applications";
  documentsPath = "${rootStoragePath}/documents";
  backupPath = "${rootStoragePath}/backup";
  mediaPath = "${rootStoragePath}/media";
  photosPath = "${rootStoragePath}/photos";

  # file."${rootStoragePath}" = {
  #   type = "dir";
  # };  
}
