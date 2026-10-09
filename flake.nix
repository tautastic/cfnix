{
  description = "NixOS + home-manager for one laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-jetbrains-plugins = {
      url = "github:nix-community/nix-jetbrains-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    redact = {
      url = "github:scuba-plaza/redact/v1.0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mufradat = {
      url = "github:scuba-plaza/mufradat";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, disko, nix-jetbrains-plugins, redact, mufradat, ... }:
  let
    system = "x86_64-linux";
    hostname = "nixos";
    stateVersion = "26.05";

    settings = import ./local/settings.nix;

    tokenLike = s: builtins.match ".*REDACTED\\[[A-Z][A-Z0-9_]*].*" s != null;
    hits = v:
      if builtins.isString v then (if tokenLike v then [ v ] else [ ])
      else if builtins.isAttrs v then
        builtins.concatMap (n: if tokenLike n then [ n ] else [ ]) (builtins.attrNames v)
        ++ builtins.concatMap hits (builtins.attrValues v)
      else if builtins.isList v then builtins.concatMap hits v
      else [ ];
    unhydrated = hits settings;

    me =
      if unhydrated == [ ] then settings
      else throw ''
        local/settings.nix still holds placeholder tokens:

          ${builtins.concatStringsSep "\n          " unhydrated}

        Fill them in from .redact/secrets.age:

            redact hydrate

        In a fresh clone, set the tool up first:

            nix shell .#redact -c redact init

        The real values stay in your working tree; git's clean filter turns
        them back into tokens on commit, so they never reach one.
      '';

    overlays = [
      (_: prev: {
        unstable = import nixpkgs-unstable {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      })
      redact.overlays.default
      mufradat.overlays.default
    ];

    pkgs = import nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };

    shells = {
      c     = { banner = "🔧 C/C++ environment ready";                            packages = p: [ p.gcc p.gnumake p.cmake ]; };
      go    = { banner = "🐹 Go environment ready $(go version)";                  packages = p: [ p.go ]; };
      hs    = { banner = "λ Haskell environment ready $(ghc --numeric-version)";  packages = p: [ p.ghc ]; };
      js    = { banner = "📦 Node.js environment ready";                           packages = p: [ p.nodejs ]; };
      lean  = { banner = "📚 Lean environment ready";                              packages = p: [ p.elan p.lean4 ]; };
      ocaml = { banner = "🐫 OCaml environment ready";                             packages = p: [ p.opam p.ocaml p.dune ]; };
      py    = { banner = "🐍 Python environment ready";                            packages = p: [ p.python3 ]; };
      zig   = { banner = "⚡ Zig environment ready $(zig version)";                packages = p: [ p.zig ]; };
    };
  in
  {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit hostname stateVersion nix-jetbrains-plugins;
        devShellNames = builtins.attrNames shells;
      };
      modules = [
        home-manager.nixosModules.home-manager
        disko.nixosModules.disko
        ./modules/options.nix
        { inherit me; nixpkgs.overlays = overlays; }
        ./hosts/nixos
      ];
    };

    devShells.${system} = builtins.mapAttrs (name: def:
      pkgs.mkShell {
        packages = def.packages pkgs;
        shellHook = ''
          echo "${def.banner}"
          care="$HOME/.local/care/${name}"
          mkdir -p "$care" && cd "$care"
        '';
      }) shells;

    packages.${system}.redact = pkgs.redact;

    formatter.${system} = pkgs.nixfmt;
  };
}
