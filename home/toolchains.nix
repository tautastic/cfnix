{ config, lib, toolchains, ... }:

let
  home = config.home.homeDirectory;
  flake = "${home}/.config/nixos";
  care = ".local/care";

  envrc = name: ''
    watch_file ${flake}/toolchains.nix ${flake}/flake.nix ${flake}/flake.lock
    use flake ${flake}#${name}
  '';
in
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global.hide_env_diff = true;
      whitelist.exact = map (name: "${home}/${care}/${name}/.envrc") (lib.attrNames toolchains);
    };
  };

  home.file = lib.mapAttrs' (name: _:
    lib.nameValuePair "${care}/${name}/.envrc" { text = envrc name; }) toolchains;
}
