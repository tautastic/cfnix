# Technical notes

How the parts of this configuration work, and why they are the way they are.

## Private values

`.gitattributes` marks `local/settings.nix` and `local/ssh.conf` with
`filter=redact`; everything `redact` does to files is scoped to those, which is
why this document can quote a token without being rewritten. Both files are
**tracked**, and what is committed is the tokenised form:

```nix
username = "REDACTED[SYS_USER]";
```

`redact hydrate` rewrites the tokens in place with the real values from
`.redact/secrets.age`, and git's clean filter turns every stored value back into
its token whenever git reads the file. So the working tree holds the real values
(which is what Nix evaluates), `git status` is clean, `git add -A` can only stage
the tokenised form, and GitHub only ever sees tokens.

Nix's git fetcher reads tracked files from the working tree, so the flake is
referenced as plain `.#nixos` with no `path:` prefix and `.git` is not copied
into the store. Nix caches evaluations by commit, not by content, so
`redact.postHydrate` in `home/git/git.nix` clears the cache after every hydrate.

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

- A new file has to be `git add`ed before Nix can see it; untracked files are
  invisible to the git fetcher.
- To change the *shape* of a private file (a third git identity, say), store the
  new value with `redact set NAME` first, then edit the real file and `git add`
  it. A value that is not stored has nothing to be replaced by.

`local/ssh.conf` is read verbatim into `/etc/ssh/ssh_config` by
`modules/services/openssh.nix`. Its only content is the token
`REDACTED[SSH_EXTRA_CONFIG]`, so ssh hosts are added with
`redact edit SSH_EXTRA_CONFIG` and a rebuild.

### The scanner

`redact check` searches for every stored value and every retired one (a value
replaced by `redact set` stays on the deny list), plus structural secrets: private
keys, age identities, password hashes, SCRAM verifiers, API tokens, home
directories, email addresses, public IPs and UUIDs. The default run scans the
working tree as it would be committed; `--staged` scans the index and `--history`
every blob reachable from any ref. `redact init` installs `--staged` as the
pre-commit hook, which fails closed when `redact` is not on `PATH`. A false
positive is allowed with a regular expression in `.redact/allow`, or a path is
excluded with `-redact-scan` in `.gitattributes` (as for `flake.nix` and `flake.lock`).

Documentation therefore never spells out a home directory or the username; write
`~` instead.

## Disk

`hosts/nixos/disk.nix` declares the layout with
[disko](https://github.com/nix-community/disko): GPT, a 2560 MiB ESP, and the
rest a LUKS container holding btrfs with `@`, `@home` and `@swap` subvolumes. disko
generates `fileSystems` and `boot.initrd.luks.devices`, so the disk is described
once, there is no generated `hardware-configuration.nix`, and no UUID is in the
repo. Devices are named by GPT partition label (`disk-main-ESP`,
`disk-main-luks`); filesystem labels would be unsafe because this ESP is labelled
`BOOT`, and so is every Linux installer USB stick.

**Compression.** `@` and `@home` are mounted `compress=zstd` (level 3). `@swap` is
left uncompressed: a btrfs swapfile is `NOCOW`, which btrfs never compresses.
Compression happens at write time, so the option only affects data written after
it took effect. To compress what is already there, once (it rewrites extents and
unshares reflinked or snapshot-shared data; this machine has no snapshots):

```sh
sudo btrfs filesystem defragment -r -czstd /
sudo btrfs filesystem defragment -r -czstd /home
compsize /home
```

**Swap.** 16 GiB, matching RAM so hibernation stays possible later, in its own
`@swap` subvolume so snapshotting `@` stays possible too. NixOS creates the file
itself with `btrfs filesystem mkswapfile`, which sets `NOCOW`. Two guards sit on
that unit: `RequiresMountsFor=/swap` (automatic), and
`ConditionPathIsMountPoint=/swap` in `hosts/nixos/hardware.nix`, so a missing
subvolume skips the unit instead of writing a 16 GiB file into the root. The
mount is `nofail`, so a missing subvolume cannot drop the boot into emergency
mode. Hibernation is deliberately not configured: `resume_offset` is a
machine-specific number that would have to be committed.

## Toolchains

`toolchains.nix` is the one registry (`c go hs js lean ocaml py zig`). Each entry
has `packages = p: [...]`, and optionally `icon`, `color`, `ides` and `env`. Four things are
generated from it:

- **Dev shells.** `devShells.<lang>` in `flake.nix`, built with `mkShell` (so gcc,
  make and patch are in every one), exporting the entry's `env` and
  `DEV_TOOLCHAIN=<lang>`, `DEV_TOOLCHAIN_ICON=<icon>` and
  `DEV_TOOLCHAIN_COLOR=<color>`. The right prompt shows the icon, in that colour,
  through the `toolchain` segment in `home/zsh/p10k.zsh`, which replaces
  p10k's `nix_shell` segment (it would print `impure`); the name is printed only
  for an entry without an icon, and any other nix shell, such as `nix-shell -p`,
  gets just the nix icon. The red `▼` beside it is p10k's `direnv` segment, shown
  while a direnv environment is loaded. The `icon` is an emoji or
  a Nerd Fonts glyph stored as the raw character (Nix has no `\u` escapes); the
  logos are Nerd Fonts private-use codepoints such as `nf-md-language_javascript`,
  not Unicode, and the Lean entry spells out `L∃∀N` because no Lean logo glyph
  exists. The `color` is a `#rrggbb` brand colour, drawn in truecolor, and each one
  has at least 5:1 contrast against the prompt's segment background
  (`POWERLEVEL9K_BACKGROUND`, 256-colour 233). Haskell, Lean and Python are
  lighter than their logos for that reason: a dark background alone cannot get
  the Lean and Python blues past 4.3:1.
- **direnv.** `home/toolchains.nix` writes `~/.local/care/<lang>/.envrc`
  (`use flake` on the matching shell) and trusts only those exact files
  (`whitelist.exact`). nix-direnv keeps the shell in `.direnv/`, a GC root, so
  `nh clean` does not collect it. The generated `.envrc` watches `toolchains.nix`
  and the flake files; a hand-written one for a project elsewhere
  (`use flake ~/.config/nixos#<lang>`) does not, and needs `nix-direnv-reload`
  after a registry change. direnv walks up, so project subfolders inherit it.
- **IDE launchers.** `home/jetbrains.nix` wraps each IDE named in an entry's
  `ides` so its `PATH` starts with that entry's packages. These wrappers carry
  only the entry's packages, not a compiler: if cgo or node-gyp needs one inside
  GoLand or WebStorm, add `p.gcc` to the `go` or `js` entry. There is no direnv
  plugin, since projects under `~/.local/care/<lang>` get the toolchain from the
  wrapper anyway.
- **Bookmarks.** `home/zsh/zsh.nix` adds `lc<lang>`, which `cd`s to
  `~/.local/care/<lang>`.

**Stable tool paths.** An IDE setting that needs an absolute executable path
cannot use `PATH`, and a `/nix/store` path goes stale with every update. So
`~/.local/share/ide-tools/<ide>/bin/` links the same tools (a `/bin`-only
`buildEnv`, via `xdg.dataFile`) and is relinked at each activation. WebStorm's
Biome plugin takes `~/.local/share/ide-tools/webstorm/bin/biome` as its
executable, written out in full with the home directory expanded. Biome from npm
does not work here: its prebuilt glibc binary is a generic dynamically linked
executable, and only the static musl build runs.

**Generic binaries.** NixOS refuses to start dynamically linked executables built
for other distributions (the `stub-ld` error), and this config has no `nix-ld`.
That is why the `js` entry sets `NPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS=false`:
a `packageManager` pin in a project would otherwise make pnpm download that exact
release and fail to start it.

**GoLand.** It passes the Global GOPATH from its own settings (Settings > Go >
GOPATH) to every `go` command, so Nix cannot manage it. It has to be
`~/.local/share/go`, or GoLand creates `~/go`.

### `env`

An entry's `env` is exported by its dev shell and by every zsh session
(`programs.zsh.sessionVariables`), and GUI applications inherit it from the
systemd user session after a login. It holds the XDG locations of each
toolchain's state (`GOPATH`, `GOMODCACHE`, `ELAN_HOME`, `OPAMROOT`,
`NPM_CONFIG_CACHE`) and the pnpm setting above.

### Lean

Nix provides only `elan` (the `lean` entry). The nixpkgs build patches the
toolchains it downloads, so no `nix-ld` is needed. Each project pins its toolchain
in `lean-toolchain` and elan installs it into `~/.local/share/elan` on first use.
There is no `lean4` package and no elan `bin` directory on `PATH`: the `lean` and
`lake` on `PATH` are elan's proxies. Mathlib projects must not be built from
source; create them with `lake init <name> math`, which fetches the prebuilt
cache, and do not run `lake update` without a reason.

## Home directory

`~` holds no application state. The base directories are declared once
(`xdg.enable` in `home/xdg.nix`) and Nix follows them
(`use-xdg-base-directories`):

| | |
|---|---|
| `~/.config` | settings: `zsh`, `docker`, `vibe`, `librewolf` |
| `~/.local/share` | data worth keeping: `go`, `elan`, `opam`, `pnpm` |
| `~/.cache` | anything that can be downloaded again: `go/mod`, `npm`, zsh history |
| `~/.local/state` | history, logs, the Nix profile |
| `~/.local/care/<lang>` | projects, one folder each |

`~/Documents`, `Downloads`, `Music`, `Pictures` and `Videos` are the only visible
folders. `Desktop`, `Public`, `Templates` and `Projects` are pointed at `~`, which
is how `user-dirs.dirs` says "none", so they are not created.

A tool that insists on a dotdirectory in `~` is redirected where it is defined:
an `env` entry in `toolchains.nix` if it belongs to a toolchain, otherwise
`home.sessionVariables` in `home/xdg.nix`. Home Manager's LibreWolf module
hardcodes `~/.librewolf`, so `home/librewolf.nix` turns those files off and writes
the overrides to `~/.config/librewolf/librewolf`, which LibreWolf uses whenever
`~/.librewolf` does not exist.

What cannot be moved stays: `~/.ssh` (OpenSSH), `~/.pki` (NSS's shared certificate
database), `~/.nv` (the NVIDIA driver's profiles), `~/.java` (the JDK's
preferences), `~/.claude` and `~/.claude.json` (Claude Code), and `~/.zshenv`, the
one stub that points zsh at `~/.config/zsh`.

## Checking a change

```sh
nix flake check                              # evaluate everything
nixos-rebuild build --flake .#nixos          # build, do not activate
sudo nixos-rebuild dry-activate --flake .#nixos
redact check --staged                        # before committing
```
