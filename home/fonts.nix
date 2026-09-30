{ pkgs, ... }:

{
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    scheherazade-new
    lalezar-fonts
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      serif = [ "Scheherazade New" "serif" ];
      sansSerif = [ "Noto Sans Arabic" "sans-serif" ];
      monospace = [ "JetBrainsMono Nerd Font" "monospace" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
