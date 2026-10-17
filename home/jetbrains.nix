{ pkgs, lib, nix-jetbrains-plugins, toolchains, ... }:

let
  pluginList = [
    "neokai"
    "ru.adelf.idea.dotenv"
    "mobi.hsz.idea.gitignore"
    "String Manipulation"
    "izhangzhihao.rainbow.brackets.lite"
  ];

  forIde = name:
    lib.filter (t: lib.elem name (t.ides or [ ])) (lib.attrValues toolchains);

  toolsFor = name: lib.concatMap (t: t.packages pkgs) (forIde name);

  toolsEnv = name: pkgs.buildEnv {
    name = "${name}-tools";
    paths = toolsFor name;
    pathsToLink = [ "/bin" ];
  };

  withToolchains = name: ide:
    let
      tools = toolsFor name;
      launcher = pkgs.writeShellScript "${name}-launcher" ''
        export PATH=${lib.makeBinPath tools}:"$PATH"
        exec ${ide}/bin/${name} "$@"
      '';
    in
    if tools == [ ] then ide else
    pkgs.symlinkJoin {
      name = "${ide.name}-with-toolchains";
      paths = [ ide ];
      postBuild = ''
        rm "$out/bin/${name}"
        ln -s ${launcher} "$out/bin/${name}"
      '';
    };

  goland = withToolchains "goland"
    (nix-jetbrains-plugins.lib.buildIdeWithPlugins pkgs pkgs.jetbrains.goland pluginList);
  webstorm = withToolchains "webstorm"
    (nix-jetbrains-plugins.lib.buildIdeWithPlugins pkgs pkgs.jetbrains.webstorm pluginList);
  installed = { inherit goland webstorm; };
in {
  home.packages = lib.attrValues installed;

  xdg.dataFile = lib.mapAttrs' (name: _:
    lib.nameValuePair "ide-tools/${name}" { source = toolsEnv name; }) installed;
}
