{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    acpid
    btrfs-progs
    cryptsetup
    lvm2
    e2fsprogs
    dosfstools
    exfatprogs
    f2fs-tools
    jfsutils
    xfsprogs
    ntfs3g
    dmidecode
    dmraid
    efibootmgr
    networkmanager
    openssh
    usbutils
    which
    curl wget rsync
    less
    redact
  ];
}
