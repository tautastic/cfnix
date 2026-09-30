#!/usr/bin/env bash

set -euo pipefail

HOST=${HOST:-nixos}
DISK=${DISK:-/dev/nvme0n1}
FLAKE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/cfnix"

die() { printf 'fail %s\n' "$*" >&2; exit 1; }
ok()  { printf '  ok %s\n' "$*"; }
log() { printf '==> %s\n' "$*"; }

command -v sfdisk >/dev/null || die "sfdisk is not installed"
[[ -b $DISK ]] || die "$DISK is not a block device"

log "Reading the labels disko expects from $FLAKE#$HOST"
esp=$(nix eval --raw "$FLAKE#nixosConfigurations.$HOST.config.fileSystems.\"/boot\".device")
luks=$(nix eval --raw "$FLAKE#nixosConfigurations.$HOST.config.boot.initrd.luks.devices" \
        --apply 'ds: (builtins.head (builtins.attrValues ds)).device')

case $esp  in /dev/disk/by-partlabel/*) esp_label=${esp#/dev/disk/by-partlabel/} ;;
              *) die "fileSystems.\"/boot\".device is $esp, not a by-partlabel path; nothing to do" ;; esac
case $luks in /dev/disk/by-partlabel/*) luks_label=${luks#/dev/disk/by-partlabel/} ;;
              *) die "the luks device is $luks, not a by-partlabel path; nothing to do" ;; esac
ok "partition 1 should be named '$esp_label'"
ok "partition 2 should be named '$luks_label'"

log "Checking $DISK looks the way disk.nix says it does"
[[ $(lsblk -no TYPE "$DISK" | grep -c '^part$') -eq 2 ]] \
  || die "$DISK does not have exactly two partitions; refusing to touch its partition table"
[[ $(lsblk -no FSTYPE --nodeps "${DISK}p1") == vfat ]] \
  || die "${DISK}p1 is not vfat; refusing"
[[ $(lsblk -no FSTYPE --nodeps "${DISK}p2") == crypto_LUKS ]] \
  || die "${DISK}p2 is not crypto_LUKS; refusing"
ok "two partitions, vfat then crypto_LUKS, as expected"

if [[ $(lsblk -no PARTLABEL --nodeps "${DISK}p1") == "$esp_label" ]] \
   && [[ $(lsblk -no PARTLABEL --nodeps "${DISK}p2") == "$luks_label" ]]; then
  ok "both partitions are already named correctly; nothing to write"
else
  mkdir -p "$STATE"
  backup="$STATE/gpt-$(basename "$DISK")-$(date +%Y%m%d-%H%M%S).sfdisk"
  log "Backing up the partition table to $backup"
  # shellcheck disable=SC2024
  sudo sfdisk -d "$DISK" > "$backup"
  ok "saved -- restore with: sudo sfdisk $DISK < $backup"

  log "Setting the GPT partition names"
  sudo sfdisk --part-label "$DISK" 1 "$esp_label"
  sudo sfdisk --part-label "$DISK" 2 "$luks_label"

  log "Confirming nothing but the names changed"
  after="$STATE/gpt-after.sfdisk"
  # shellcheck disable=SC2024
  sudo sfdisk -d "$DISK" > "$after"
  strip_names() { sed -E 's/,[[:space:]]*name=.*$//' "$1"; }
  unexpected=$(diff <(strip_names "$backup") <(strip_names "$after") || true)
  if [[ -n $unexpected ]]; then
    printf '%s\n' "$unexpected" >&2
    die "the partition table changed beyond the names -- restore from $backup"
  fi
  ok "start, size, type and uuid are all unchanged"

  log "Refreshing the kernel's view"
  sudo partx -u "$DISK" \
    || printf ' warn partx failed; the by-partlabel links will appear after a reboot\n' >&2
fi

missing=0
for l in "$esp_label" "$luks_label"; do
  if [[ -e /dev/disk/by-partlabel/$l ]]; then
    ok "/dev/disk/by-partlabel/$l -> $(readlink -f "/dev/disk/by-partlabel/$l")"
  else
    printf ' warn /dev/disk/by-partlabel/%s does not exist yet\n' "$l" >&2
    missing=1
  fi
done

if [[ $missing -eq 1 ]]; then
  cat <<'STALE'

The names are on the disk but this kernel has not picked them all up. The
initrd builds these links from the on-disk table, so a reboot resolves it --
but verify them after rebooting before you remove the old generation.
STALE
fi

cat <<'NEXT'

Next
  sudo nixos-rebuild boot --flake ~/.config/nixos#nixos
  reboot

`boot` and not `switch`: all three mount device strings change, and switch would
try to unmount /home. The current generation keeps its own initrd and stays in
the boot menu as a fallback.
NEXT
