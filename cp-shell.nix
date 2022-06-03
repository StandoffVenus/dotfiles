{ writeShellScriptBin, shell-nix, envrc }:

let 
  name = "cp-shell";
in writeShellScriptBin name ''
  cp ${shell-nix} ./shell.nix
  cp ${envrc} ./.envrc
''
