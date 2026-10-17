{
  c     = { icon = "󰙱"; color = "#659ad2"; packages = p: [ p.gcc p.gnumake p.cmake ]; };
  go    = { icon = "󰟓"; color = "#00add8"; packages = p: [ p.go ]; ides = [ "goland" ]; env = { GOPATH = "$HOME/.local/share/go"; GOMODCACHE = "$HOME/.cache/go/mod"; }; };
  hs    = { icon = "󰲒"; color = "#a074c4"; packages = p: [ p.ghc ]; };
  js    = { icon = "󰌞"; color = "#f7df1e"; packages = p: [ p.nodejs_24 p.unstable.pnpm p.unstable.biome ]; ides = [ "webstorm" ]; env = { NPM_CONFIG_CACHE = "$HOME/.cache/npm"; NPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS = "false"; }; };
  lean  = { icon = "L∃∀N"; color = "#5d83d2"; packages = p: [ p.elan ]; env = { ELAN_HOME = "$HOME/.local/share/elan"; }; };
  ocaml = { icon = ""; color = "#ec6813"; packages = p: [ p.opam p.ocaml p.dune ]; env = { OPAMROOT = "$HOME/.local/share/opam"; }; };
  py    = { icon = "󰌠"; color = "#4b8bbe"; packages = p: [ p.python3 ]; };
  zig   = { icon = ""; color = "#f7a41c"; packages = p: [ p.zig ]; };
}
