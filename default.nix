{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (builtins) toString;
  inherit (lib.attrsets) attrValues filterAttrs mapAttrs mapAttrsToList;
  inherit (lib.modules) mkAliasOptionModule mkDefault mkIf;
  # inherit (lib.my) mapModulesRec';
in {
  # imports =
  #   [    
  #   ]
  #   ++ (mapModulesRec' (toString ./modules) import);

  # Common config for all nixos machines;
  environment.variables = {
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";

    # nixPath =
    #   nixPathInputs
    #   ++ [
    #     "nixpkgs-overlays=${config.snowflake.dir}/overlays"
    #     "snowflake=${config.snowflake.dir}"
    #   ];

    # registry = registryInputs // {snowflake.flake = inputs.self;};

    settings = {
      auto-optimise-store = true;
      # substituters = ["https://nix-community.cachix.org" "https://hyprland.cachix.org"];
      # trusted-public-keys = [
      #   "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      #   "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      # ];
    };
  };

  

  # Some reasonable, global defaults
  ## This is here to appease 'nix flake check' for generic hosts with no
  ## hardware-configuration.nix or fileSystem config.
  fileSystems."/".device = mkDefault "/dev/disk/by-label/nixos";

  # boot = {
  #   kernelPackages = mkDefault pkgs.linuxPackages_latest;
  #   kernelParams = ["pcie_aspm.policy=performance"];
  #   loader = {
  #     efi.efiSysMountPoint = "/boot";
  #     efi.canTouchEfiVariables = mkDefault true;
  #     grub = {
  #       enable = mkDefault true;
  #       device = "nodev";
  #       efiSupport = mkDefault true;
  #       useOSProber = mkDefault true;
  #     };
  #   };
  # };

  # console = {
  #   font = mkDefault "Lat2-Terminus16";
  #   useXkbConfig = mkDefault true;
  # };

  time.timeZone = mkDefault "America/New_York";
  i18n.defaultLocale = mkDefault "en_US.UTF-8";

  # WARNING: prevent installing pre-defined packages
  # environment.defaultPackages = [];

  # environment.systemPackages =
  #   attrValues {inherit (pkgs) cached-nix-shell gnumake unrar unzip;};

  system = {
    stateVersion = "23.11";
    configurationRevision = with inputs; mkIf (self ? rev) self.rev;
  };
}
