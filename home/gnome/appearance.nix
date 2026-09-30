{ ... }:

{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-format = "24h";
      clock-show-weekday = true;
      clock-show-date = true;
    };

    "org/gnome/desktop/privacy" = {
      disable-camera = true;
      remember-recent-files = false;
      remove-old-trash-files = true;
      remove-old-temp-files = true;
      old-files-age = "uint32 1";
    };
    "org/gnome/desktop/notifications".show-in-lock-screen = false;
    "org/gnome/desktop/location".enabled = false;
    "org/gnome/desktop/screen-time-limits".history-enabled = false;
    "org/gnome/desktop/search-providers".disable-external = true;
    "org/gnome/desktop/datetime".automatic-timezone = false;

    "org/gnome/mutter" = {
      edge-tiling = true;
      dynamic-workspaces = false;
      workspaces-only-on-primary = true;
    };
    "org/gnome/desktop/wm/preferences".num-workspaces = 4;
    "org/gnome/shell/app-switcher".current-workspace-only = false;

    "org/gnome/desktop/peripherals/mouse" = {
      left-handed = false;
      accel-profile = "flat";
      speed = -0.15;
      natural-scroll = false;
    };

    "org/gtk/settings/file-chooser".clock-format = "24h";
    "org/gtk/gtk4/settings/file-chooser" = {
      show-hidden = true;
      sort-directories-first = true;
    };

    "org/gnome/nautilus/list-view" = {
      default-column-order = [
        "name" "date_modified" "size" "group" "owner" "permissions" "type"
        "date_created" "date_accessed" "recency" "detailed_type"
      ];
      default-visible-columns = [ "name" "date_modified" "size" "permissions" ];
      default-zoom-level = "small";
    };
    "org/gnome/nautilus/preferences" = {
      date-time-format = "detailed";
      default-folder-viewer = "list-view";
      migrated-gtk-settings = true;
      show-create-link = true;
      show-delete-permanently = true;
    };
  };
}
