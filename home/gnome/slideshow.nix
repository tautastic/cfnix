{ gnome-slideshow, ... }:

{
  imports = [ gnome-slideshow.homeManagerModules.gnome-slideshow ];

  services.gnome-slideshow = {
    enable = true;
    wallpaperDirectory = ./wallpapers;
    duration = 1800;
  };
}