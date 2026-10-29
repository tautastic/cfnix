{ config, ... }:

let
  home = config.home.homeDirectory;
in
{
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = home;
      publicShare = home;
      templates = home;
      projects = home;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications."x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
  };

  home.sessionVariables = {
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    VIBE_HOME = "${config.xdg.configHome}/vibe";
  };
}
