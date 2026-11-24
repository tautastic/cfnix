{ pkgs, ... }:

{
  home.packages = [ pkgs.fragments ];

  # Every key of the Fragments schema, at its default. Edit a value here to
  # change it. The download directory and speed limits are not dconf keys;
  # Fragments keeps those in its own Transmission daemon.
  dconf.settings."de/haeckerfelix/Fragments" = {
    # notify when a torrent finishes downloading
    enable-notifications-downloaded = true;
    # notify when a torrent is added
    enable-notifications-new-torrent = true;
    # move the .torrent file to the trash once it has been added
    trash-original-torrent-files = false;
    # keep the system from suspending while torrents are active
    inhibit-suspend-active-torrents = true;
    # let other devices connect to this Transmission daemon
    remote-access = false;

    # Window state the app rewrites itself. Setting these here would reset
    # them on every switch, so they stay commented out.
    # window-width = 900;
    # window-height = 700;
    # client-last-connection = "00000000-0000-0000-0000-000000000000";
  };

  xdg.mimeApps.defaultApplications = {
    "application/x-bittorrent" = "de.haeckerfelix.Fragments.desktop";
    "x-scheme-handler/magnet" = "de.haeckerfelix.Fragments.desktop";
  };
}
