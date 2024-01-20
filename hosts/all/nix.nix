{ config, lib, inputs, ... }:

let

  inherit (lib) mkIf mapAttrs;
  inherit (builtins) toString;

in {

  # Nix Settings
  nix = {
    settings = {      
      experimental-features = [ 
        # Enable flakes and new 'nix' command
        "nix-command" 
        "flakes" 
        "repl-flake" 
        # "auto-allocate-uids"
        # Allow derivation builders to call Nix, and thus build derivations recursively.
        "recursive-nix"
      ];

      # auto-allocate-uids = true; 

      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      # Root and sudo users
      trusted-users = [ "root" "@wheel" ];

      # Supress annoying warning
      warn-dirty = false;

      # builders = 

      # Speed up remote builds
      # builders-use-substitutes = true;
    };

    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 90d";
    };

    # Add each flake input as a registry
    # To make nix3 commands consistent with the flake
    registry = mapAttrs (_: value: { flake = value; }) inputs;

  };


  # Map registries to channels
  # Very useful when using legacy commands
  nix.nixPath = let path = toString ./.; in [ "repl=${path}/repl.nix" "nixpkgs=${inputs.nixpkgs}" ];

  # Automatically upgrade this system while I sleep
  system.autoUpgrade = {
    enable = false;
    dates = "04:00";
    flake = "/etc/nixos#${config.networking.hostName}";
    flags = [ 
      "--update-input" "nixpkgs"
      "--update-input" "unstable"
      "--update-input" "nur"
      "--update-input" "home-manager"
      "--update-input" "agenix"
      "--update-input" "impermanence"
      # "--commit-lock-file" 
    ];
    allowReboot = true;
  };

}
