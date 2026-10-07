{ config, ... }:

{
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ config.me.username ];
    };
  };

  programs.ssh.extraConfig = builtins.readFile ../../local/ssh.conf;
}
