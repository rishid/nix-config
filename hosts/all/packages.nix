{ config, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # System Enviroment & Packages
  # ---------------------------------------------------------------------------
  environment = {

    # List packages installed in system profile
    systemPackages = with pkgs; [ 
      inetutils mtr sysstat gnumake gitMinimal # basics
      file curl htop tmux rsync vim jq
      usbutils pciutils zip unzip nmap arp-scan dig lsof 
      cryptsetup binutils keychain rsync
      silver-searcher wget
      # nix-zsh-completions zsh-completions 
      # nix-bash-completions bash-completion
      home-manager # include home-manager command
      # nixos-cli # found in overlays
      # cachix # binary cache
    ];

    # Add terminfo files
    enableAllTerminfo = true;

  };

}
