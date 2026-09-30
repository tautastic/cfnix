{ config, lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.me = {
    username = mkOption {
      type = types.strMatching "[a-z_][a-z0-9_-]*";
      description = "The one human account on this machine.";
    };

    passwordHash = mkOption {
      type = types.strMatching "\\$[0-9a-z]+\\$.*";
      description = "Hash for that account and for root, as mkpass produces.";
    };

    postgresVerifier = mkOption {
      type = types.strMatching "SCRAM-SHA-256\\$.*";
      description = "SCRAM verifier for the postgres role of the same name.";
    };

    databases = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Databases to ensure exist, owned by that role.";
    };

    git = {
      default = mkOption {
        type = types.str;
        description = "Which identity git uses when a repo does not say.";
      };

      identities = mkOption {
        description = "Signing/authoring identities, switched with git-identity.";
        type = types.attrsOf (types.submodule {
          options = {
            email = mkOption { type = types.str; };
            key = mkOption {
              type = types.str;
              description = "Filename of the ssh key under ~/.ssh.";
            };
            color = mkOption {
              type = types.ints.between 0 255;
              description = "256-colour index for the prompt segment.";
            };
          };
        });
      };
    };
  };

  config.assertions = [
    {
      assertion = config.me.git.identities ? ${config.me.git.default};
      message = ''
        me.git.default is "${config.me.git.default}", which is not one of the
        identities in local/settings.nix (${
          lib.concatStringsSep ", " (lib.attrNames config.me.git.identities)
        }).
      '';
    }
  ];
}
