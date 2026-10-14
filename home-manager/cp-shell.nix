{ writeShellScriptBin, shell-nix, envrc }:

let 
  name = "cp-shell";
in writeShellScriptBin name ''
  set -e
  cp ${shell-nix} ./shell.nix
  cp ${envrc} ./.envrc
  chmod u+w ./shell.nix ./.envrc
''
