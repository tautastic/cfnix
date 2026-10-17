# cfnix

A flake-based NixOS configuration for one laptop: GNOME on Wayland, home-manager
for everything under `~`, and a zsh / powerlevel10k / kitty / vis / yazi /
zathura / librewolf setup.

The repo is public and nothing identifying is committed. The two files that hold
private values are committed **tokenised**, and a git filter fills the real values
back in on the machine, so a clone builds and a commit never contains one.

## From a clean install

```sh
git clone <this repo> ~/.config/nixos
cd ~/.config/nixos

mkdir -p ~/.config/redact
cp /path/to/identity.txt ~/.config/redact/   # carried from the old machine
nix shell .#redact -c redact init            # git filter, hooks, fills local/*

sudo nixos-rebuild switch --flake .#nixos
```

`redact init` sets up the git filter and hooks and fills `local/*` from
`.redact/secrets.age`. Until it has run, evaluation stops with a message naming
the tokens that are still placeholders. Without the identity file nobody can read
the store, so keep `~/.config/redact/identity.txt` backed up.

Git calls `redact`, so it has to be on `PATH` whenever git touches this repo.
`modules/packages.nix` installs it from the first switch on; until then run git
inside `nix shell .#redact`.

## Daily use

- **Rebuild:** `nix-make`. `-b` makes the new generation the boot default without
  switching, `-u` updates the flake inputs.
- **Develop:** no toolchain is installed globally. `cd` into `~/.local/care/<lang>`
  (or use the bookmark `lc<lang>`, such as `lcgo`) and direnv loads that
  language's tools; leaving unloads them. GoLand and WebStorm get the same tools.
- **Add or change a toolchain:** edit `toolchains.nix`; the dev shells, direnv
  files, IDE launchers and bookmarks all follow from it.
- **Private values:** `redact edit NAME` changes one, `redact check` scans for a
  leak. A new file has to be `git add`ed before Nix can see it.

## Layout

```
flake.nix          inputs, the one nixosConfiguration, and the devShells
toolchains.nix     the toolchain registry: dev shells, direnv, IDE launchers, env
bin/               nix-make
local/             the two files that carry private values
.redact/           the encrypted value store and its recipients; useless without
                   an identity
hosts/nixos/       this machine: module list, disk layout, hardware facts
modules/           system modules, imported by hosts/nixos
home/              everything under ~, imported by hosts/nixos via home-manager
```

How the private-value filter, the disk, the toolchains and the home directory
layout work is in [TECHNICAL.md](TECHNICAL.md).
