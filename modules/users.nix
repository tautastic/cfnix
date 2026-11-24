{ config, pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.${config.me.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "dialout" ];
    initialHashedPassword = config.me.passwordHash;
    shell = pkgs.zsh;
  };

  users.users.root.hashedPassword = config.me.passwordHash;

  security.sudo.wheelNeedsPassword = true;
}