{ writeShellScript }: writeShellScript "initgo.sh" ''
set -e
if [ -z "$1" ]; then echo "Must provide a package name."; exit 1; fi

cat > default.nix <<EOF
{ pkgs ? import <nixpkgs> {} }:

let
  hash = null;
in pkgs.buildGoModule {
  name = "$1";
  version = "1.0.0";

  src = pkgs.lib.cleanSource ./.;

  runVend = false;
  proxyVendor = true;
  vendorSha256 = hash;

  # Temporary fix for not being able to debug via Delve in vim-go
  # This just makes the -trimpath flag disappear from GOFLAGS
  allowGoReference = true;
}
EOF

echo "use nix" >> .envrc
''
