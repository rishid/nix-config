{
  description = "NixOS systems and tools";

  # This is the standard format for flake.nix.
  # `inputs` are the dependencies of the flake,
  # and `outputs` function will return all the build results of the flake.
  # Each item in `inputs` will be passed as a parameter to
  # the `outputs` function after being pulled and built.

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # home-manager, used for managing user configuration
    # home-manager = {
    #   url = "github:nix-community/home-manager/release-23.11";
    #   # The `follows` keyword in inputs is used for inheritance.
    #   # Here, `inputs.nixpkgs` of home-manager is kept consistent with
    #   # the `inputs.nixpkgs` of the current flake,
    #   # to avoid problems caused by different versions of nixpkgs.
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";
    treefmt-nix.url = github:numtide/treefmt-nix;

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # my private secrets, it's a private repository, you need to replace it with your own.
    # use ssh protocol to authenticate via ssh-agent/ssh-key, and shallow clone to save time
    # mysecrets = {
    #   url = "git+ssh://git@github.com/ryan4yin/nix-secrets.git?shallow=1";
    #   flake = false;
    # };

    # add git hooks to format nix code before commit
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    nixpkgs,
    nixpkgs-unstable,
    disko,
    pre-commit-hooks,
    ...
  }: let
    # FIXME nixpkgs.lib.extend
    myLib = (import ./lib {inherit (nixpkgs) lib targetSystem;});

    inherit (lib.my) mapModulesX;
    inherit (builtins) listToAttrs attrNames hasAttr filter getAttr readDir;
    inherit (nixpkgs.lib)
      nixosSystem attrValues traceValSeqN
      concatMap filterAttrs foldr getAttrFromPath hasSuffix mapAttrs'
      mapAttrsToList nameValuePair recursiveUpdate removeSuffix unique;
    # inherit (inputs.nixpkgs) lib;
    inherit (inputs.nixpkgs.lib.filesystem) listFilesRecursive;
    # inherit (lib) mapAttrsToList hasSuffix;

    system = "x86_64-linux";

    # mkPkgs = pkgs: extraOverlays:
    #   import pkgs {
    #     inherit system;
    #     config.allowUnfree = true;
    #     # overlays = extraOverlays ++ (lib.attrValues self.overlays);
    #   };
    # pkgs = mkPkgs nixpkgs [self.overlays.default];
    # pkgs-unstable = mkPkgs nixpkgs-unstable [];
    pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
    };

    # mkSystem = import ./mksystem.nix {
    #   inherit nixpkgs inputs;
    # };

    mkSystem =
      { hostname
      , user ? "rishi"
      , system ? "x86_64-linux"
      , extraModules ? []
      , ...}:
        let
          systemModules = (attrValues (self.nixosModules));
        in nixosSystem {
          inherit system;
          specialArgs = { inherit lib inputs system; };
          modules = [
            { networking.hostName = hostname; }
            (./hosts/${hostname})
            (./users/${user}/nixos.nix)
            ./.   # /default.nix
          # ] ++ overlayModules ++ systemModules ++ configModules ++ extraModules;          
          ] ++ systemModules ++ extraModules;
        };

    # lib = nixpkgs:
    #     nixpkgs.lib.extend
    #     (final: prev: (import ./lib final));

    lib = nixpkgs.lib.extend (final: prev: {
      my = import ./lib {
        inherit pkgs inputs;
        lib = final;
      };
    });

    # Get Nix files in a directory, excluding "default.nix"
    # getNixFilesInDir = dir: builtins.filter (f: lib.hasSuffix ".nix" f && f != "default.nix") (builtins.attrNames (builtins.readDir dir));

    # # Whether a path exists and is a directory.
    # pathIsDirectory = path:
    #   builtins.pathExists path && builtins.readFileType path == "directory";

    # # Generate a module for a Nix file
    # moduleForFile = dir: file: { config }: {
    #   imports = [ "/${dir}${file}" ];
    # };

    # # Collect modules recursively from a directory
    # collectModulesRecursive = dir:
    #   let
    #     modules = builtins.mapAttrs (n: f: moduleForFile dir f) (getNixFilesInDir dir);
    #     subdirModules = builtins.mapAttrs (n: d: collectModulesRecursive d) (builtins.filter pathIsDirectory (builtins.attrValues (builtins.readDir dir)));
    #   in
    #     builtins.foldl' (x: y: x // y) modules subdirModules;


    # pre-commit-check = pre-commit-hooks.lib.${system}.run {
    #   src = self.outPath;
    #   hooks = {
    #     alejandra.enable = true;
    #     deadnix.enable = true;
    #     statix.enable = true;
    #   };
    # };

  in {

    # below block is sample from nix forum
    # getNixFilesInDir = dir: builtins.filter (file: lib.hasSuffix ".nix" file && file != "default.nix") (builtins.attrNames (builtins.readDir dir));
    #   genKey = str: lib.replaceStrings [ ".nix" ] [ "" ] str;
    #   genValue = dir: str: { config }: { imports = [ "/${dir}${str}" ]; };
    #   moduleFrom = dir: str: { "${genKey str}" = genValue dir str; };
    #   modulesFromDir = dir: builtins.foldl' (x: y: x // (moduleFrom dir y)) { } (getNixFilesInDir dir);
    # nixosModules = modulesFromDir ./modules;
    # end block

    # checks = {inherit pre-commit-check;};

    # lib = lib.my;

    # packages."${system}" = mapModules ./packages (p: pkgs.callPackage p {});

    # nixosModules =
    #   {
    #     snowflake = import ./.;
    #     # agenix.nixosModules.default;
    #   }
    #   // mapModulesRec ./modules import;

    # nixosModules = (mapModules ./modules/nixos import) // (mapModules ./modules/common import);
    nixosModules = (mapModulesX ./modules import);
    # nixosModules = collectModulesRecursive ./modules;
    # builtins.trace self.nixosModules: self.nixosModules;
    # foo = builtins.trace ''${self.nixosModules}'' (mapModulesX ./modules import);
    # nixosConfigurations = mapHosts ./hosts {};

    # mkSystem: https://github.com/peel/dotfiles/blob/main/flake.nix
    nixosConfigurations = {
      "server" = mkSystem {
        hostname = "server";
        system = "x86_64-linux";
        extraModules = [
          disko.nixosModules.disko
          ./hosts/server
          ./users/rishi/nixos.nix
        #   # ./modules/nixos/setup
        #   # ./modules/common/setup/hassio.nix
        ];
      };
    };

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

  };

}
