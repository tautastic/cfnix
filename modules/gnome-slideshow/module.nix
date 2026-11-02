{ config, lib, pkgs, ... }:

let
  cfg = config.services.gnome-slideshow;
in
{
  options.services.gnome-slideshow = {
    enable = lib.mkEnableOption "GNOME XML wallpaper slideshow";

    wallpaperDirectory = lib.mkOption {
      type = lib.types.path;
      description = "A directory containing .png, .jpg, or .jpeg wallpapers.";
    };

    duration = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Seconds each wallpaper is displayed.";
    };
  };

  config = lib.mkIf cfg.enable (
    let
      wallpaperDir = cfg.wallpaperDirectory;
      entries = builtins.readDir wallpaperDir;

      isImage = name: type:
        type == "regular" &&
        (lib.hasSuffix ".png"  name ||
         lib.hasSuffix ".jpg"  name ||
         lib.hasSuffix ".jpeg" name ||
         lib.hasSuffix ".PNG"  name ||
         lib.hasSuffix ".JPG"  name ||
         lib.hasSuffix ".JPEG" name);

      imageNames = lib.sort (a: b: a < b)
        (lib.filter (name: isImage name entries.${name}) (builtins.attrNames entries));

      n = lib.length imageNames;

      mkStatic = name: ''
        <static>
          <duration>${toString cfg.duration}</duration>
          <file>${wallpaperDir}/${name}</file>
        </static>'';

      blocks = map mkStatic imageNames;

      slideshowXml = pkgs.writeText "gnome-slideshow.xml" ''
        <background>
          <starttime>
            <year>2020</year><month>01</month><day>01</day>
            <hour>00</hour><minute>00</minute><second>00</second>
          </starttime>
          ${lib.concatStringsSep "\n    " blocks}
        </background>
      '';
    in
    {
      assertions = [{
        assertion = n > 0;
        message = "gnome-slideshow: no PNG or JPEG files found in ${toString wallpaperDir}";
      }];

      home.file.".local/share/gnome-background-properties/slideshow.xml".source = slideshowXml;

      dconf.settings."org/gnome/desktop/background" = {
        picture-uri      = "file://${config.home.homeDirectory}/.local/share/gnome-background-properties/slideshow.xml";
        picture-uri-dark = "file://${config.home.homeDirectory}/.local/share/gnome-background-properties/slideshow.xml";
        color-shading-type = "solid";
        primary-color = "#000000";
      };
    }
  );
}