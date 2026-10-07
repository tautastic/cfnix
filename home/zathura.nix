{ lib, ... }:

let
  allModes = [ "" "index" "fullscreen" "presentation" ];
  mapForModes   = key: action: modes: lib.listToAttrs (map (mode: { name = if mode == "default" || mode == "" then key else "[${mode}] ${key}"; value = action; }) modes);
  unmapForModes = key: modes: lib.concatStringsSep "\n" (map (mode: "unmap ${if mode == "default" || mode == "" then key else "[${mode}] ${key}"}") modes);
in
{
  programs.zathura = {
    enable = true;

    options = {
      recolor = true;
      guioptions = "s";
    };

    mappings =
      mapForModes "f" "follow" allModes
      // mapForModes "F" "display_link" allModes
      // mapForModes "<C-f>" "toggle_fullscreen" [ "" "index" "fullscreen" ]
      // mapForModes "<C-p>" "toggle_presentation" [ "" "index" "presentation" ];

    extraConfig = ''
      ${unmapForModes "F5" allModes}
      ${unmapForModes "F11" allModes}
      set selection-clipboard clipboard
    '';
  };
}
