{
  description = "Reusable Home-Manager module for GNOME wallpaper slideshows";

  outputs = { self }: {
    homeManagerModules.gnome-slideshow = ./module.nix;
  };
}