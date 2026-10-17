{ config, lib, pkgs, toolchains, ... }:

let
  bookmarks = import ./bookmarks.nix;
  inherit (bookmarks) fileBookmarks;

  careBookmarks = lib.listToAttrs (map (lang: {
    name = "lc${lang}";
    value = "~/.local/care/${lang}";
  }) (lib.attrNames toolchains));
  dirBookmarks = bookmarks.dirBookmarks // careBookmarks;

  dirAliases = builtins.mapAttrs (_: path: "cd ${path} && ls") dirBookmarks;
  fileAliases = builtins.mapAttrs (_: path: "$EDITOR ${path}") fileBookmarks;

  namedDirs = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (name: path: "hash -d ${name}=${path}") dirBookmarks);

  toolchainEnv = lib.foldl' (acc: t: acc // (t.env or { })) { } (lib.attrValues toolchains);

  instantPrompt = ''
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi
  '';

  interactive = ''
    autoload -U colors && colors
    if [[ -o interactive ]] && [[ -t 0 ]]; then
      stty stop undef
    fi
    setopt interactive_comments
    bindkey -s '^f' '^ucd "$(dirname "$(fzf)")"\n'

    path+=(
      $HOME/.local/bin
      $GOPATH/bin
      $HOME/.local/share/pnpm/bin
    )
    export PATH

    tmp() {
      local dir
      dir=$(mktemp -d) || return 1
      cd "$dir" || return 1
      if [ $# -ge 1 ]; then
        $EDITOR "$1"
      fi
    }

    gencomp() {
      if (( $# < 1 )); then
        print -u2 "usage: gencomp <command> [name]"
        return 2
      fi
      local bin=$1 name=''${2:-''${1:t}} tmpfile
      local dir=''${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions
      mkdir -p $dir || return 1
      tmpfile=$(mktemp) || return 1
      if ! $bin completion zsh >| $tmpfile || [[ ! -s $tmpfile ]]; then
        command rm -f $tmpfile
        print -u2 "gencomp: $bin produced no zsh completion script"
        return 1
      fi
      command mv $tmpfile $dir/_$name || return 1
      chmod 644 $dir/_$name
      command rm -f ''${ZDOTDIR:-$HOME}/.zcompdump
      print "gencomp: wrote $dir/_$name (run 'exec zsh')"
    }

    [[ -f "${config.xdg.configHome}/zsh/.p10k.zsh" ]] && source "${config.xdg.configHome}/zsh/.p10k.zsh"

    # Written by the ocaml devShell, absent otherwise.
    [[ ! -r "$OPAMROOT/opam-init/init.zsh" ]] \
      || source "$OPAMROOT/opam-init/init.zsh" >/dev/null 2>&1

    # Named directories
    ${namedDirs}
  '';
in
{
  xdg.configFile."zsh/.p10k.zsh".source = ./p10k.zsh;
  home.file."${config.xdg.dataHome}/zsh/site-functions/.keep".text = "";

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    syntaxHighlighting.enable = true;
    autocd = true;

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];

    completionInit = ''
      fpath=(''${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions $fpath)
      autoload -U compinit && compinit
    '';

    history = {
      size = 1000;
      save = 1000;
      path = "${config.xdg.cacheHome}/zsh/history";
      ignoreDups = false;
    };

    sessionVariables = {
      EDITOR = "vis";
      VISUAL = "vis";
      BROWSER = "librewolf";
      LOCAL_BIN = "$HOME/.local/bin";
    } // toolchainEnv;

    initContent = lib.mkMerge [
      (lib.mkOrder 500 instantPrompt)
      (lib.mkOrder 1000 interactive)
    ];

    shellAliases = {
      g = "git";
      v = "$EDITOR";
      yz = "yazi";
      cp = "cp -iv";
      mv = "mv -iv";
      rm = "rm -vI";
      mkd = "mkdir -pv";
      ip = "ip -color=auto";
      ffmpeg = "ffmpeg -hide_banner";
      grep = "grep --color=auto";
      diff = "diff --color=auto";
      ls = "eza -lAh --color=auto --git --header --group --group-directories-first";
      cpr = "rsync -HAXhaxvPS --numeric-ids --stats";
    } // dirAliases // fileAliases;
  };
}
