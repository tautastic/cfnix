{ pkgs, ... }:

let
  mkpass = pkgs.writers.writePython3Bin "mkpass"
    {
      libraries = [ pkgs.python3Packages.scramp ];
      flakeIgnore = [ "E501" ];
    }
    (builtins.readFile ./mkpass.py);

  nix-passwd = pkgs.writeShellApplication {
    name = "nix-passwd";
    runtimeInputs = [ pkgs.mkpasswd ];
    text = ''
      read -rsp 'Password: ' p1; echo
      read -rsp 'Confirm:  ' p2; echo
      [[ $p1 == "$p2" ]] || { echo 'passwords do not match' >&2; exit 1; }
      printf '%s' "$p1" | mkpasswd -m sha-512 -s
    '';
  };
in
{
  home.packages = [ mkpass nix-passwd ];

  home.file.".local/bin/nix-make" = {
    source = ../bin/nix-make;
    executable = true;
  };
}
