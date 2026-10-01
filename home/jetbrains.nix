{ pkgs, nix-jetbrains-plugins, ... }:

let
  pluginList = [
    "neokai"
    "ru.adelf.idea.dotenv"
    "mobi.hsz.idea.gitignore"
    "String Manipulation"
    "izhangzhihao.rainbow.brackets.lite"
  ];
  goland = nix-jetbrains-plugins.lib.buildIdeWithPlugins pkgs pkgs.jetbrains.goland pluginList;
  webstorm = nix-jetbrains-plugins.lib.buildIdeWithPlugins pkgs pkgs.jetbrains.webstorm pluginList;
in {
  home.packages = with pkgs; [
    goland
    webstorm
  ];
}
