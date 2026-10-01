# cfnix

A flake-based NixOS configuration for one laptop: GNOME on Wayland, home-manager
for everything under `~`, and a zsh / powerlevel10k / kitty / vis / yazi /
zathura / librewolf setup.

The repo is public and nothing identifying is committed. The two files that hold
private values are committed **tokenised** and hydrated in place on the machine,
so a clone builds and `git` never sees a real value.

## From a clean install

```sh
git clone <this repo> ~/.config/nixos
cd ~/.config/nixos

cp /path/to/key.txt ~/.config/age/     # carried from the old machine
./bin/redact hydrate                   # fills local/*, pins them, drops nix's eval cache
./scripts/install-hooks.sh             # pre-commit secret scan

sudo nixos-rebuild switch --flake .#nixos
```

Without the age key, `redact hydrate` prompts for each `@@<NAME>@@` and saves the
answer, so a from-scratch setup works too. Until it has run, evaluation stops
with a message naming the tokens that are still placeholders — it will not build
a system for a user who does not exist.

After the first switch, `nh os switch` is the short form.

## Layout

```
flake.nix          inputs, the one nixosConfiguration, and the devShells
.redacted          which files carry private values
local/             those files

secrets.age        the encrypted token -> value map; committed, useless without the key
bin/redact         the tool that manages it; needs to run before anything is built
hosts/nixos/       this machine: module list, disk layout, hardware facts
modules/           system modules, imported by hosts/nixos
home/              everything under ~, imported by hosts/nixos via home-manager
scripts/           the pre-commit hook installer
```

## Private values

`.redacted` lists the files that carry private values -- currently `local/settings.nix`
and `local/ssh.conf`. Everything `redact` does is scoped to that list, which is why
this README can quote a token without being rewritten.

`local/settings.nix` and `local/ssh.conf` are **tracked**, and what is committed
is the tokenised form:

```nix
username = "@@SYS_USER@@";
```

`redact hydrate` rewrites those tokens in place with the real values from
`secrets.age` and then sets git's `skip-worktree` bit, so:

- the working tree holds the real values, which is what Nix evaluates;
- `git status` is clean and `git add -A` cannot stage them;
- `git` — and therefore GitHub — only ever sees tokens.

This is why the flake can be referenced as plain `.#nixos`. Nix's git fetcher
reads tracked files from the working tree, so no `path:` prefix is needed and
`.git` is not copied into the store.

| command | when |
|---|---|
| `redact hydrate` | after a clone, or after changing a value in the map |
| `redact edit` | change the map itself |
| `redact set . NAME < file` | set one value from a file |
| `redact stage [file]` | tokenise the working copy into the git index, ready to commit |
| `redact check [--staged\|--history]` | scan for a value that should have been tokenised |

Two rules follow from the scheme:

- **A new file has to be `git add`ed before Nix can see it.** Untracked files are
  invisible to the git fetcher; the error names the file.
- **To change the *shape* of a private file** (a third git identity, say), edit
  the real file, then `redact stage` it. The index gets the tokenised version.
  Add the new token's value with `redact set` first, or the scan will refuse it.

### Adding an ssh host

`local/ssh.conf` is a plain `ssh_config`, read verbatim into
`/etc/ssh/ssh_config` by `modules/services/openssh.nix`.

```sh
$EDITOR local/ssh.conf
redact set . SSH_EXTRA_CONFIG < local/ssh.conf   # so it survives a re-clone
nh os switch
```

### The scanner

`redact check`'s deny list *is* the map, so it needs no separate maintenance.
It also catches structural secrets the map cannot know about: password hashes,
SCRAM verifiers, private keys, hardware UUIDs, public IPs and real email
addresses.

The tree scan deliberately skips the `skip-worktree` files — those hold real
values on purpose. `--staged` and `--history` do not skip them, and those are the
only two places a value could actually escape. `scripts/install-hooks.sh`
installs `--staged` as a pre-commit hook that fails closed.

## The disk

`hosts/nixos/disk.nix` declares the layout with
[disko](https://github.com/nix-community/disko): GPT, a 2560 MiB ESP, and the
rest a LUKS container holding btrfs with `@`, `@home` and `@swap` subvolumes,
`@` and `@home` compressed with zstd.
disko generates `fileSystems` and `boot.initrd.luks.devices` from it, so the disk
is described once and there is no generated `hardware-configuration.nix` to keep
in step — and no UUID anywhere in the repo.

Devices are named by GPT partition label (`disk-main-ESP`, `disk-main-luks`)
rather than by UUID or by filesystem label. Filesystem labels would be unsafe
here: this ESP is labelled `BOOT`, and so is every Linux installer USB stick.

### Compression

`/` and `/home` are mounted `compress=zstd` (level 3, btrfs's default). `@swap`
is deliberately left uncompressed: `btrfs filesystem mkswapfile` marks the
swapfile `NOCOW`, and btrfs never compresses a `NOCOW` file, so the option would
be meaningless there. `/boot` is vfat and cannot compress.

btrfs compresses at write time, per extent, so **the mount option only affects
data written after it takes effect.** Everything already on the disk stays
uncompressed until it is rewritten. To compress what is already there, once:

```sh
sudo btrfs filesystem defragment -r -czstd /
sudo btrfs filesystem defragment -r -czstd /home
compsize /home          # check what it achieved
```

That rewrites extents, so it takes a while and it unshares any reflinked or
snapshot-shared data — worth knowing before running it on a machine that has
snapshots. This one has none.

### Swap

16 GiB, as a swapfile in its own `@swap` subvolume. The size matches RAM, so
hibernation stays possible later; the dedicated subvolume means snapshotting `@`
stays possible too, which an active swapfile inside `@` would block.

NixOS creates the file itself on first activation, and does it correctly on
btrfs — `mkswap-swap-swapfile.service` uses `btrfs filesystem mkswapfile`, which
marks the file `NOCOW` as btrfs requires. Two guards sit on that unit:

- `RequiresMountsFor=/swap`, generated automatically, so it cannot run before the
  subvolume is mounted;
- `ConditionPathIsMountPoint=/swap`, set in `hosts/nixos/hardware.nix`, so if the
  `@swap` subvolume is missing the unit is skipped rather than writing a 16 GiB
  file into the root subvolume by mistake.

The `/swap` mount is `nofail`, so a missing subvolume can never drop the boot
into emergency mode.

Hibernation is deliberately **not** configured: `resume_offset` is a
machine-specific number that would have to be read off the disk with
`btrfs inspect-internal map-swapfile` and committed, which is exactly the kind of
value this repo just finished removing.

### Aligning an existing install

On a machine installed before this spec existed, the partitions have no GPT names
and `@swap` does not exist. `scripts/align-disk.sh` reads the expected names and
subvolumes out of the built config, refuses unless the disk matches `disk.nix`,
backs up the partition table, and creates whatever is missing:

```sh
./scripts/align-disk.sh
sudo nixos-rebuild switch --flake .#nixos
```

It is idempotent — with everything already in place it writes nothing and needs
no `sudo`. If it has to rename partitions, use `nixos-rebuild boot` and reboot
instead of `switch`, because the mount device strings change and `switch` would
try to unmount `/home`.

### Dev shells

`nix develop .#go`, and the same for `c hs js lean ocaml py zig`. Each one drops
you in `~/.local/care/<lang>`, creating it if needed. The `nix-<lang>` aliases
are the short form.

## Rebuilding

```sh
nix flake check                              # evaluate everything
nixos-rebuild build --flake .#nixos          # build, do not activate
sudo nixos-rebuild dry-activate --flake .#nixos
sudo nixos-rebuild switch --flake .#nixos
```
