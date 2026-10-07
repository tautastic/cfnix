{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    filterAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    types;

  cfg = config.programs.vis;

  themeName =
    if cfg.theme == null
    then null
    else lib.removeSuffix ".lua" (builtins.baseNameOf cfg.theme);

  luaString = value:
    let
      escaped = builtins.replaceStrings
        [ "\\" "'" "\n" "\r" ]
        [ "\\\\" "\\'" "\\n" "\\r" ]
        value;
    in
      "'${escaped}'";

  luaValue = value:
    if builtins.isBool value then
      if value then "true" else "false"
    else if builtins.isInt value then
      toString value
    else
      luaString value;

  configuredSettings =
    filterAttrs (_: value: value != null) cfg.settings;

  configuredWindowSettings =
    filterAttrs (_: value: value != null) cfg.windowSettings;

  renderGlobalSetting = name: value:
    "vis.options.${name} = ${luaValue value}";

  renderWindowSetting = name: value:
    "win.options.${name} = ${luaValue value}";

  settingsLua =
    concatStringsSep "\n"
      (mapAttrsToList renderGlobalSetting configuredSettings);

  windowSettingsLua =
    concatStringsSep "\n"
      (mapAttrsToList renderWindowSetting configuredWindowSettings);

  keymapsLua =
    concatStringsSep "\n"
      (mapAttrsToList
        (mode: mappings:
          let
            luaMode = {
              normal = "NORMAL";
              operatorPending = "OPERATOR_PENDING";
              visual = "VISUAL";
              visualLine = "VISUAL_LINE";
              insert = "INSERT";
              replace = "REPLACE";
            }.${mode};
          in
            concatStringsSep "\n"
              (mapAttrsToList
                (key: action:
                  "vis:map(vis.modes.${luaMode}, ${luaString key}, ${luaString action})"
                )
                mappings)
        )
        cfg.keymaps);

  visrc = ''
    require('vis')

    ${lib.optionalString (themeName != null) ''
      vis.events.subscribe(vis.events.WIN_OPEN, function(win)
        vis:command("set theme ${luaString themeName}")
      end)
    ''}

    vis.events.subscribe(vis.events.INIT, function()
      ${settingsLua}

      ${keymapsLua}

      ${cfg.extraLuaConfig}
    end)

    vis.events.subscribe(vis.events.WIN_OPEN, function(win)
      ${windowSettingsLua}
    end)
  '';

in
{
  options.programs.vis = {
    enable = mkEnableOption "vis";

    package = mkOption {
      type = types.package;
      default = pkgs.vis;
      defaultText = lib.literalExpression "pkgs.vis";
    };

    defaultEditor = mkOption {
      type = types.bool;
      default = false;
    };

    theme = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a Vis Lua theme.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          autoindent = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          changecolors = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          escdelay = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
          };

          ignorecase = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          loadmethod = mkOption {
            type = types.nullOr (
              types.enum [ "auto" "read" "mmap" ]
            );
            default = null;
          };

          shell = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
        };
      };

      default = {};
    };

    windowSettings = mkOption {
      type = types.submodule {
        options = {
          breakat = mkOption {
            type = types.nullOr types.str;
            default = null;
          };

          colorcolumn = mkOption {
            type = types.nullOr types.int;
            default = null;
          };

          cursorline = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          expandtab = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          numbers = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          relativenumbers = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          numberwidth = mkOption {
            type = types.nullOr types.int;
            default = null;
          };

          showeof = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          shownewlines = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          showspaces = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          showtabs = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          statusbar = mkOption {
            type = types.nullOr types.bool;
            default = null;
          };

          tabwidth = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
          };

          wrapcolumn = mkOption {
            type = types.nullOr types.int;
            default = null;
          };
        };
      };

      default = {};
    };

    keymaps = mkOption {
      type = types.submodule {
        options = {
          normal = mkOption {
            type = types.attrsOf types.str;
            default = {};
          };

          operatorPending = mkOption {
            type = types.attrsOf types.str;
            default = {};
          };

          visual = mkOption {
            type = types.attrsOf types.str;
            default = {};
          };

          visualLine = mkOption {
            type = types.attrsOf types.str;
            default = {};
          };

          insert = mkOption {
            type = types.attrsOf types.str;
            default = {};
          };

          replace = mkOption {
            type = types.attrsOf types.str;
            default = {};
          };
        };
      };

      default = {};
    };

    extraLuaConfig = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];

    xdg.configFile =
      {
        "vis/visrc.lua".text = visrc;
      }
      // optionalAttrs (cfg.theme != null) {
        "vis/themes/${themeName}.lua".source = cfg.theme;
      };

    home.sessionVariables = mkIf cfg.defaultEditor {
      EDITOR = "vis";
      VISUAL = "vis";
    };
  };
}
