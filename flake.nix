{
  description = "NixOS systems configurations";

  # This is the standard format for flake.nix.
  # `inputs` are the dependencies of the flake,
  # and `outputs` function will return all the build results of the flake.
  # Each item in `inputs` will be passed as a parameter to
  # the `outputs` function after being pulled and built.

  inputs = {
    # <https://search.nixos.org/packages>
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    # <https://mipmip.github.io/home-manager-option-search>
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS profiles for different hardware
    # <https://github.com/NixOS/nixos-hardware>
    hardware.url = "github:NixOS/nixos-hardware";

    treefmt-nix.url = github:numtide/treefmt-nix;

    # NixOS Secrets
    # <https://github.com/ryantm/agenix>
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";

    # Home Manager Secrets
    # <https://github.com/jordanisaacs/homeage>
    homeage.url = "github:jordanisaacs/homeage";
    homeage.inputs.nixpkgs.follows = "nixpkgs";

    # Nix User Repository
    # <https://nur.nix-community.org>
    nur.url = "github:nix-community/NUR";   

    # add git hooks to format nix code before commit
    # pre-commit-hooks = {
    #   url = "github:cachix/pre-commit-hooks.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

  };

  # `outputs` are all the build result of the flake.
  #
  # A flake can have many use cases and different types of outputs.
  # 
  # parameters in function `outputs` are defined in `inputs` and
  # can be referenced by their names. However, `self` is an exception,
  # this special parameter points to the `outputs` itself(self-reference)
  # 
  # The `@` syntax here is used to alias the attribute set of the
  # inputs's parameter, making it convenient to use inside the function.
  outputs = inputs @ {
    self,
    ...
  }: let
    inherit (self) outputs inputs; 
    inherit (builtins) length;
    inherit (this.lib) mkAttrs mkUsers mkAdmins mkModules mapModules;

    # Initialize this configuration with inputs and binary caches
    this = import ./lib { inherit inputs; };

    # Get configured pkgs for a given system with overlays, nur and unstable baked in
    mkPkgs = this: import inputs.nixpkgs rec {

      # System & other options is set in default.nix
      system = this.system;

      # Accept agreements for unfree software
      config.allowUnfree = true;
      # config.nvidia.acceptLicense = true;
      # config.joypixels.acceptLicense = true;

      # Add to-be-updated packages blocking builds (none right now)
      config.permittedInsecurePackages = [];

      # Modify pkgs with this, scripts, packages, nur and unstable
      overlays = [ 

        # this and personal library
        (final: prev: { inherit this; })
        (final: prev: { this = import ./overlays/lib { inherit final prev; }; })

      #   # Personal scripts
      #   (final: prev: import ./overlays/bin { inherit final prev; } )
      #   (final: prev: mkAttrs ./overlays/bin ( name: prev.callPackage ./overlays/bin/${name} {} ))

      #   # Additional packages
      #   (final: prev: import ./overlays/pkgs { inherit final prev; } )
      #   (final: prev: mkAttrs ./overlays/pkgs ( name: prev.callPackage ./overlays/pkgs/${name} {} ))

        # Nix User Repositories 
        (final: prev: { nur = import inputs.nur { pkgs = final; nurpkgs = final; }; })

        # Unstable nixpkgs channel
        (final: prev: { unstable = import inputs.nixpkgs-unstable { inherit system config; }; })

      ];

    };

    # Make a NixOS system configuration 
    mkConfiguration = this: inputs.nixpkgs.lib.nixosSystem rec {

      # Make nixpkgs for this system (with overlays)
      pkgs = mkPkgs this;
      system = pkgs.this.system;
      specialArgs = { inherit inputs outputs; this = pkgs.this; };

      # Include NixOS configurations, modules, secrets and caches
      modules = this.modules.root ++ (if (length this.users < 1) then [] else [

        # Include Home Manager module (if there are any users besides root)
        inputs.home-manager.nixosModules.home-manager { 
          home-manager = {

            # Inherit NixOS packages
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs outputs; this = pkgs.this; };

            # Include Home Manager configuration, modules, secrets and caches
            users = mkAttrs this.users ( 
              user: ( ({ imports }: { inherit imports; }) { 
                imports = this.modules."${user}";
              } )
            ); 

          }; 
        } 

      ]);
    };

    # pre-commit-check = pre-commit-hooks.lib.${system}.run {
    #   src = self.outPath;
    #   hooks = {
    #     alejandra.enable = true;
    #     deadnix.enable = true;
    #     statix.enable = true;
    #   };
    # };

    # Flake outputs
  in {

    # NixOS configurations found in configurations directory
    nixosConfigurations = mkAttrs ./hosts (

      # Make configuration for each subdirectory 
      host: mkConfiguration (this // import ./hosts/${host} // { 
        users = mkUsers host;
        admins = mkUsers host;
        # Once secret management is added, can go back to using this method
        # admins = mkAdmins host;
        modules = mkModules host;
      })

    );

  };

}

    # checks = {inherit pre-commit-check;};

    # nixosModules = (mapModules ./modules import);

    # # mkSystem: https://github.com/peel/dotfiles/blob/main/flake.nix
    # nixosConfigurations = {
    #   "server" = mkSystem {
    #     hostname = "server";
    #     system = "x86_64-linux";
    #     extraModules = [
    #       disko.nixosModules.disko
    #       ./hosts/server
    #       ./users/rishi/nixos.nix
    #     ];
    #   };

    # };

    # nixosConfigurations = {
    #   "server" = nixpkgs.lib.nixosSystem {
    #     system = "x86_64-linux";
    #     modules =
    #     [
    #       disko.nixosModules.disko
    #       ./hosts/server
    #       ./users/rishi/nixos.nix
    #     ];
    #   };
    # };

    # By default, NixOS will try to refer the nixosConfiguration with
    # its hostname, so the system named `nixos-test` will use this one.
    # However, the configuration name can also be specified using:
    #   sudo nixos-rebuild switch --flake /path/to/flakes/directory#<name>
    #
    # The `nixpkgs.lib.nixosSystem` function is used to build this
    # configuration, the following attribute set is its parameter.
    #
    # Run the following command in the flake's directory to
    # deploy this configuration on any NixOS system:
    #   sudo nixos-rebuild switch --flake .#nixos-test

    # nixosConfigurations = {
    #   "nixos" = nixpkgs.lib.nixosSystem {
    #     system = "x86_64-linux";

        # The Nix module system can modularize configuration,
        # improving the maintainability of configuration.
        #
        # Each parameter in the `modules` is a Nixpkgs Module, and
        # there is a partial introduction to it in the nixpkgs manual:
        #    <https://nixos.org/manual/nixpkgs/unstable/#module-system-introduction>
        # It is said to be partial because the documentation is not
        # complete, only some simple introductions.
        # such is the current state of Nix documentation...
        #
        # A Nixpkgs Module can be an attribute set, or a function that
        # returns an attribute set. By default, if a Nixpkgs Module is a
        # function, this function have the following default parameters:
        #
        #  lib:     the nixpkgs function library, which provides many
        #             useful functions for operating Nix expressions:
        #             https://nixos.org/manual/nixpkgs/stable/#id-1.4
        #  config:  all config options of the current flake, very useful
        #  options: all options defined in all NixOS Modules
        #             in the current flake
        #  pkgs:   a collection of all packages defined in nixpkgs,
        #            plus a set of functions related to packaging.
        #            you can assume its default value is
        #            `nixpkgs.legacyPackages."${system}"` for now.
        #            can be customed by `nixpkgs.pkgs` option
        #  modulesPath: the default path of nixpkgs's modules folder,
        #               used to import some extra modules from nixpkgs.
        #               this parameter is rarely used,
        #               you can ignore it for now.
        #
        # The default parameters mentioned above are automatically
        # generated by Nixpkgs. However, if you need to pass other non-default 
        #  parameters to the submodules, you'll have to manually configure
        # these parameters using `specialArgs`. you must use `specialArgs` by 
        # uncomment the following line:
        # specialArgs = {...};  # pass custom arguments into all sub module.
      #   modules =
      #     [
      #       disko.nixosModules.disko
      #       ./hosts/server
      #       ./users/rishi/nixos.nix
      #     ];
      # };
    # };

#   };

# }
