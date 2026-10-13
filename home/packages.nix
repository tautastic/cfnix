{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    p7zip
    poppler
    resvg
    imagemagick
    exiftool
    mediainfo
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

    mufradat
  ] ++ [
    pkgs.unstable.picard
    pkgs.unstable.biome
    pkgs.unstable.pnpm
    pkgs.unstable.claude-code
    pkgs.unstable.yt-dlp
  ];
}