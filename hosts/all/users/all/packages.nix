{ config, pkgs, ... }: {

  # ---------------------------------------------------------------------------
  # User Environment & Packages
  # ---------------------------------------------------------------------------

  home.packages = with pkgs; [ 
    killall
    lf
    sysz
    tealdeer
    lsd
  ];

  # Enable home-manager, git & zsh
  programs = {
    home-manager.enable = true;
    direnv.enable = true;
  };

}
