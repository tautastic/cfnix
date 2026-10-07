{ ... }:

{
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}
