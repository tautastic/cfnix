{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    p7zip
    poppler
    resvg
    imagemagick
    exiftool
    picard
    amberol
    loupe
    showtime

    jq
    fd
    fzf
    zoxide
    eza
    wl-clipboard

    compsize

    gnome-disk-utility
    nautilus

    anki
    localsend

    gcc
    gnumake
    go
    nodejs_24

    age
  ] ++ [
    pkgs.unstable.pnpm_12
    pkgs.unstable.biome
    pkgs.unstable.claude-code
  ];
}
