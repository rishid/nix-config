{ pkgs, inputs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  # environment.pathsToLink = [ "/share/fish" ];

  # Add ~/.local/bin to PATH
  # environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.fish.enable = true;

  users.users.rishi = {
    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ];    
    shell = pkgs.fish;
    # hashedPassword = "";
    openssh.authorizedKeys.keys  = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID/W4zB/IqV+O9s8MMiIq+7BobnEkUUQf0wkZTpL7WpZ dhupar@Dhupars-MacBook-Air"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXm2SFCDKxeYHRM7SClgUh9S/oZKBYRItGTbgDmY/gY rdhupar@bos-mpl6a 2024-01-05T15:03:49Z"
    ];
  };
  
}
