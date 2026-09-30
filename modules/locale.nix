{ lib, ... }:

let
  regional = "de_DE.UTF-8";
  regionalKeys = [
    "LC_ADDRESS" "LC_IDENTIFICATION" "LC_MEASUREMENT" "LC_MONETARY" "LC_NAME"
    "LC_NUMERIC" "LC_PAPER" "LC_TELEPHONE" "LC_TIME"
  ];
in
{
  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = lib.genAttrs regionalKeys (_: regional);

  console.keyMap = "us";
  services.xserver.xkb.layout = "us";
}
