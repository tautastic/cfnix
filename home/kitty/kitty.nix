{ ... }:

{
  programs.kitty = {
    enable = true;

    themeFile = "Earthsong";

    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      font_size = 18.0;
    };
  };

  dconf.settings."org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
    name = "Launch Kitty";
    command = "kitty --start-as=maximized";
    binding = "<Super>Return";
  };
}
