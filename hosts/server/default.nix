{ options, config, inputs, lib, pkgs, ... }:

with builtins;
with lib;
with lib.my;
let 
  inherit (inputs) disko;
in {
  imports = [
    # disko.nixosModules.disko
    # ../../users/rishi/nixos.nix
    ../common.nix
    ./hardware-configuration.nix
    ./disko-config.nix	
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    # package = pkgs.nixFlakes;
    # Be sure to run nix-collect-garbage one time per week
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 90d";
    };
    settings = {
      # Replace identical files in the nix store with hard links
      auto-optimise-store = true;
      # Unify many different Nix package manager utilities
      # https://nixos.org/manual/nix/stable/command-ref/experimental-commands.html
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true; 
  boot.loader.efi.canTouchEfiVariables = true;

  powerManagement.powertop.enable = true;

  programs.fish.enable = true;
  programs.nix-ld.enable = true;
  programs.ssh.startAgent = true;

  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.tailscale.extraUpFlags = ["--ssh" ];

  # Modules
  # modules.hardware = {
  #   fs = {
  #     enable = true;
  #     ssd.enable = true;
  #   };
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    age
    binutils # for strings and nm
    dig
    dpkg
    file
    gitMinimal
    htop
    keychain
    lm_sensors
    nfs-utils
    nix-index
    patchelf
    pciutils
    powertop
    rsync
    silver-searcher
    stdenv
    stdenv.cc    
    tailscale
    unrar
    unzip
    usbutils
    vim
    wget
    wget
  ];

  systemd = {
    services.clear-log = {
      description = "Clear >2 month-old logs every week";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=60d";
      };
    };
    timers.clear-log = {
      wantedBy = [ "timers.target" ];
      partOf = [ "clear-log.service" ];
      timerConfig.OnCalendar = "weekly UTC";
    };
 
    # force enable ASPM. Newer kernels do not enable by default.
    services.realtek-aspm = {
      enable =
        lib.versionAtLeast config.boot.kernelPackages.kernel.version "5.5";
      description =
        "Enable power-saving states for Realtek NIC";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      # the device ID and states that need to be enabled may change per device
      script = ''
        echo 1 | tee /sys/bus/pci/drivers/r8169/0000\:02\:00.0/link/l1_2_aspm
      '';
    };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}
