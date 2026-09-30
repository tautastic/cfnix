{ config, hostname, stateVersion, nix-jetbrains-plugins, ... }:

{
  imports = [
    ./disk.nix
    ./hardware.nix
    ../../modules/audio.nix
    ../../modules/boot.nix
    ../../modules/desktop/gnome.nix
    ../../modules/locale.nix
    ../../modules/networking.nix
    ../../modules/nix.nix
    ../../modules/packages.nix
    ../../modules/services/docker.nix
    ../../modules/services/openssh.nix
    ../../modules/services/postgresql.nix
    ../../modules/users.nix
  ];

  networking.hostName = hostname;
  system.stateVersion = stateVersion;

  me.databases = [ "tasrif_db" ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit (config) me;
      inherit stateVersion nix-jetbrains-plugins;
    };
    users.${config.me.username} = import ../../home;
  };
}
