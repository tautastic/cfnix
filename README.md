# cfnix

A flake-based NixOS configuration for one laptop: GNOME on Wayland, home-manager
for everything under `~`, and a zsh / powerlevel10k / kitty / vis / yazi /
zathura / librewolf setup.

The repo is public and nothing identifying is committed. The two files that hold
private values are committed **tokenised** and a git filter fills the real
values back in on the machine, so a clone builds and a commit never contains one.

## From a clean install

```sh
git clone <this repo> ~/.config/nixos
cd ~/.config/nixos

mkdir -p ~/.config/redact
cp /path/to/identity.txt ~/.config/redact/   # carried from the old machine
nix shell .#redact -c redact init            # git filter, hooks, fills local/*

sudo nixos-rebuild switch --flake .#nixos
```

`redact init` configures the git filter, installs the pre-commit, post-checkout
and post-merge hooks, and hydrates `local/*` from `.redact/secrets.age`. Until it
has run, evaluation stops with a message naming the tokens that are still
placeholders — it will not build a system for a user who does not exist.

The filter and the hooks call `redact`, so it has to be on `PATH` whenever git
touches this repo. `modules/packages.nix` installs it, which means from the first
switch on; until then run git inside `nix shell .#redact`.

After the first switch, `nh os switch` is the short form.

## Layout

```
flake.nix          inputs, the one nixosConfiguration, and the devShells
.gitattributes     which files run through the redact filter
local/             those files

.redact/           secrets.age, the encrypted NAME -> value store, and recipients,
                   who can read it; committed, useless without an identity
hosts/nixos/       this machine: module list, disk layout, hardware facts
modules/           system modules, imported by hosts/nixos
home/              everything under ~, imported by hosts/nixos via home-manager
```

## Private values

`.gitattributes` marks the files that carry private values with `filter=redact`
-- currently `local/settings.nix` and `local/ssh.conf`. Everything `redact` does
to files is scoped to those, which is why this README can quote a token without
being rewritten.

`local/settings.nix` and `local/ssh.conf` are **tracked**, and what is committed
is the tokenised form:

```nix
username = "REDACTED[SYS_USER]";
```

`redact hydrate` rewrites those tokens in place with the real values from
`.redact/secrets.age`, and git's clean filter turns every stored value back into
its token whenever git reads the file, so:

- the working tree holds the real values, which is what Nix evaluates;
- `git status` is clean and `git add -A` can only stage the tokenised form;
- `git` — and therefore GitHub — only ever sees tokens.

This is why the flake can be referenced as plain `.#nixos`. Nix's git fetcher
reads tracked files from the working tree, so no `path:` prefix is needed and
`.git` is not copied into the store.

Nix caches evaluations by commit, not by content, so a hydrate that changes a
value would otherwise leave a stale cache behind. `redact.postHydrate` in
`home/git/git.nix` clears it after every hydrate.

| command | when |
|---|---|
| `redact hydrate` | after a clone or pull changed a value; the post-checkout and post-merge hooks run it |
| `redact set NAME` | store a value, from stdin or a hidden prompt; redacted files are rehydrated |
| `redact edit NAME` | change a value in `$EDITOR`; rehydrates on save |
| `redact add PATH…` | mark a file as redacted and stage it tokenised |
| `redact list` | names, where they are used, and which have no value |
| `redact status` | check the identity, store, recipients, filter, hooks and files |
| `redact check [--staged\|--history]` | scan for a value that should have been tokenised |

Two rules follow from the scheme:

- **A new file has to be `git add`ed before Nix can see it.** Untracked files are
  invisible to the git fetcher; the error names the file.
- **To change the *shape* of a private file** (a third git identity, say), store
  the new value with `redact set NAME` first, then edit the real file and
  `git add` it. The filter puts the token in the index; a value that is not
  stored has nothing to be replaced by.

Without its identity nobody can read `.redact/secrets.age`, so keep
`~/.config/redact/identity.txt` backed up.

### Adding an ssh host

`local/ssh.conf` is a plain `ssh_config`, read verbatim into
`/etc/ssh/ssh_config` by `modules/services/openssh.nix`. Its only content is the
token `REDACTED[SSH_EXTRA_CONFIG]`, so the hosts live in that value:

```sh
redact edit SSH_EXTRA_CONFIG
nh os switch
```

### The scanner

`redact check` searches for every stored value, and for every retired one: a
value replaced by `redact set` stays on the deny list. So it needs no separate
maintenance. It also catches structural secrets the store cannot know about:
private keys, age identities, password hashes, SCRAM verifiers, API tokens,
home directories, email addresses, public IPs and UUIDs.

The default run scans the working tree as it would be committed, redacted files
tokenised first. `--staged` scans the index and `--history` every blob reachable
from any ref; those are the places a value could actually escape. `redact init`
installs `--staged` as the pre-commit hook, which fails closed when `redact` is
not on `PATH`. A false positive is allowed with a regular expression in
`.redact/allow`.

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
