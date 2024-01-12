{ config, lib, pkgs, ... }: 

let

  # agenix secrets combined secrets toggle
  secrets = config.age.secrets // { inherit (config.modules.secrets) enable; };

in {

  # Disallow modifying users outside of this config
  users.mutableUsers = false;  

  # Allow root to work with git on the /etc/nixos directory
  system.activationScripts.root.text = ''
    printf "[safe]\ndirectory = /etc/nixos" > /root/.gitconfig
  '';

}
