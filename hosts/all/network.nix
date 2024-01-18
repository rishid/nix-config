{ config, this, ... }: {

  # ---------------------------------------------------------------------------
  # System Networking
  # ---------------------------------------------------------------------------

  networking = {

    # Hostname passed as argument from flake
    hostName = this.host; 
    domain = this.domain;

    # Fewer IP addresses, please
    enableIPv6 = false;

    # Firewall
    firewall.enable = true;

  };

  boot.kernelModules = [ "tcp_bbr" ];
  # boot.kernel.sysctl = {
  #  "net.core.default_qdisc" = "fq";
  #  "net.ipv4.tcp_congestion_control" = "bbr";
  # };

  # services.resolved.enable = true;

}
