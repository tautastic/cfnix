{ config, lib, pkgs, me, ... }:

let
  registry = me.git;
  inherit (registry) default identities;

  keyPath = id: "${config.home.homeDirectory}/.ssh/${id.key}";
  sshCommand = id: "ssh -i ${keyPath id} -o IdentitiesOnly=yes";

  identityFile = name: id: ''
    [user]
    	name = ${name}
    	email = ${id.email}

    [core]
    	sshCommand = "${sshCommand id}"
  '';

  gitIdentity = pkgs.writeShellApplication {
    name = "git-identity";
    runtimeInputs = [ pkgs.git pkgs.openssh ];
    text = builtins.readFile ./git-identity.sh;
  };

  zshMap = name: pairs: ''
    ${name}=(
    ${lib.concatStringsSep "\n"
      (map (p: "  ${lib.escapeShellArg p.key} ${lib.escapeShellArg p.value}") pairs)}
    )'';

  promptTable = ''
    typeset -gA _git_identity_name _git_identity_key _git_identity_color
    ${zshMap "_git_identity_name"
      (lib.mapAttrsToList (n: id: { key = id.email; value = n; }) identities)}
    ${zshMap "_git_identity_key"
      (lib.mapAttrsToList (n: id: { key = n; value = keyPath id; }) identities)}
    ${zshMap "_git_identity_color"
      (lib.mapAttrsToList (n: id: { key = n; value = toString id.color; }) identities)}
  '';

in {
  home.packages = [ gitIdentity ];

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      user.name = default;
      user.email = identities.${default}.email;
      core.sshCommand = sshCommand identities.${default};
    };
  };

  xdg.configFile = lib.mapAttrs'
    (name: id: lib.nameValuePair "git/identities/${name}" { text = identityFile name id; })
    identities;

  home.file."${config.xdg.configHome}/zsh/git-identity.zsh".text =
    promptTable + "\n" + builtins.readFile ./prompt.zsh;

  home.file."${config.xdg.dataHome}/zsh/site-functions/_git-identity".source = ./_git-identity;

  programs.zsh.initContent = lib.mkOrder 1500 ''
    source "${config.xdg.configHome}/zsh/git-identity.zsh"
  '';
}
