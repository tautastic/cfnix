{ config, stateVersion, ... }:

{
  imports = [
    ./fonts.nix
    ./git/git.nix
    ./gnome/appearance.nix
    ./gnome/keybindings.nix
    ./jetbrains.nix
    ./kitty/kitty.nix
    ./librewolf.nix
    ./local-bin.nix
    ./packages.nix
    ./vis/vis.nix
    ./yazi/yazi.nix
    ./zathura.nix
    ./zsh/zsh.nix
  ];

  home.stateVersion = stateVersion;

  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;

  programs.home-manager.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
    flake = "${config.home.homeDirectory}/.config/nixos";
  };

  programs.nix-your-shell = {
    enable = true;
    enableZshIntegration = true;
    nix-output-monitor.enable = false;
  };
}
