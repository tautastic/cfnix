{ lib, ... }:

let
  unbind = names: lib.genAttrs names (_: [ ]);

  numbered = prefix: range: map (n: "${prefix}${toString n}") range;
  spare = lib.range 5 12;
  corners = [ "ne" "nw" "se" "sw" ];
  sides = [ "e" "n" "s" "w" ];
  directions = [ "up" "down" "left" "right" ];
in
{
  home.keyboard = {
    enable = true;
    model = "pc105";
    layout = "us,de,ar";
    variant = ",,mac";
    options = [ "grp:win_space_toggle" ];
  };

  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      sources = map (l: lib.hm.gvariant.mkTuple [ "xkb" l ]) [ "us" "de" "ara" ];
      per-window = false;
    };

    "org/gnome/desktop/wm/keybindings" = unbind ([
      "activate-window-menu" "begin-move" "begin-resize"
      "cycle-group" "cycle-group-backward" "cycle-panels" "cycle-panels-backward"
      "cycle-windows" "cycle-windows-backward"
      "lower" "maximize" "minimize" "move-to-center"
      "panel-main-menu" "panel-run-dialog" "raise" "raise-or-lower"
      "set-spew-mark" "show-desktop" "show-osd"
      "switch-applications-backward" "switch-group" "switch-group-backward"
      "switch-input-source-backward" "switch-panels" "switch-panels-backward"
      "switch-windows" "switch-windows-backward"
      "toggle-fullscreen" "toggle-on-all-workspaces" "toggle-shaded" "unmaximize"
    ]
    ++ map (c: "move-to-corner-${c}") corners
    ++ map (s: "move-to-side-${s}") sides
    ++ map (d: "move-to-monitor-${d}") directions
    ++ map (d: "move-to-workspace-${d}") directions
    ++ map (d: "switch-to-workspace-${d}") directions
    ++ numbered "move-to-workspace-" spare
    ++ numbered "switch-to-workspace-" spare
    ) // {
      close = [ "<Super>q" ];
      toggle-maximized = [ "<Super>f" ];
      switch-applications = [ "<Super>Tab" ];
      switch-input-source = [ "<Super>space" ];
    }
    // lib.listToAttrs (map (n: {
      name = "switch-to-workspace-${toString n}";
      value = [ "<Super>${toString n}" ];
    }) (lib.range 1 4))
    // lib.listToAttrs (map (n: {
      name = "move-to-workspace-${toString n}";
      value = [ "<Super><Shift>${toString n}" ];
    }) (lib.range 1 4));

    "org/gnome/shell/keybindings" = unbind [
      "disable-extension-version-validation" "focus-active-notification"
      "open-application-menu" "screenshot" "screenshot-window"
      "show-screen-recording-controls" "show-screenshot-ui" "show-world-clock"
      "toggle-application-view" "toggle-message-tray" "toggle-quick-settings"
    ] // {
      toggle-overview = [ "<Super>" ];
    };

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ "<Shift><Super>Left" ];
      toggle-tiled-right = [ "<Shift><Super>Right" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = unbind [
      "email" "help" "magnifier" "magnifier-zoom-in" "magnifier-zoom-out"
      "play" "prev" "next" "rotate-video-lock" "screensaver" "screenreader"
      "screenshot" "screenshot-clip" "search" "terminal"
      "volume-down" "volume-mute" "volume-up"
      "window-screenshot" "window-screenshot-clip"
    ] // {
      home = [ "<Super>h" ];
      www = [ "<Super>w" ];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
  };
}
