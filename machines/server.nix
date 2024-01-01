{ config, pkgs, ... }: {
  imports = [
    ./common.nix
  ];

  # force enable ASPM. Newer kernels do not enable by default.
  systemd.services = {
    realtek-aspm = {
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
