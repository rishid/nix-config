{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [ 
    emacs
    # neofetch
    # yo
    # firefox-wayland
  ];

  programs = {
    git.enable = true;
    tmux.enable = true;
    zsh.enable = true;
  };

  # terminal du jour
  # modules.kitty.enable = true;

}
