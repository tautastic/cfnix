{ config, pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    initLua = ./init.lua;

    plugins = {
      inherit (pkgs.yaziPlugins) full-border;
    };

    flavors = {
      "flexoki-dark" = ./flavors/flexoki-dark.yazi;
    };

    theme.flavor = {
      dark = "flexoki-dark";
      light = "flexoki-dark";
    };

    settings = {
      mgr = {
        ratio = [ 1 3 4 ];
        sort_by = "natural";
        sort_sensitive = true;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "none";
        show_hidden = true;
        show_symlink = true;
      };

      preview = {
        image_filter = "lanczos3";
        image_quality = 90;
        tab_size = 1;
        max_width = 600;
        max_height = 900;
        cache_dir = "${config.xdg.cacheHome}/yazi";
        ueberzug_scale = 1;
        ueberzug_offset = [ 0 0 0 0 ];
      };

      tasks = {
        micro_workers = 5;
        macro_workers = 10;
        bizarre_retry = 5;
      };

      opener = {
        edit = [ { run = ''$EDITOR %s''; block = true; desc = "Edit"; } ];
        xdot = [ { run = ''xdot "$1"''; orphan = true; desc = "Open with xdot"; } ];
      };

      open = {
        prepend_rules = [
          { url = "*.dot"; use = ["xdot" "edit"]; }
        ];
      };
    };
  };
}
