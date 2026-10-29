{ pkgs, ... }:

let
  # vibe-rs is a passthru derivation, so its tests must be disabled separately
  mistral-vibe-no-tests = pkgs.unstable.mistral-vibe.overrideAttrs (old: {
    doCheck = false;
    doInstallCheck = false;
    passthru = old.passthru // {
      vibe-rs = old.passthru.vibe-rs.overrideAttrs { doCheck = false; };
    };
  });

  # nixpkgs' uv wrapper defaults UV_SYSTEM_CERTS=1, which aborts in the build
  # sandbox (SSL_CERT_FILE=/no-cert-file.crt) even with UV_OFFLINE=1
  anki-no-system-certs = pkgs.anki.overrideAttrs (old: {
    env = old.env // { UV_SYSTEM_CERTS = "0"; };
  });
in
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

    anki-no-system-certs
    localsend

    age

    mufradat
    music-manager

    mistral-vibe-no-tests
  ] ++ [
    pkgs.unstable.picard
    pkgs.unstable.claude-code
    pkgs.unstable.yt-dlp
  ];
}