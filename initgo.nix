{ writeShellScript }: writeShellScript "initgo.sh" ''
    set -e
    if [ -z "$1" ]; then echo "Must provide a package name."; exit 1; fi

    cat > default.nix <<EOF
        { pkgs ? import <nixpkgs> {} }:

        pkgs.buildGoModule {
          name = "$1";
          version = "1.0.0";

          src = pkgs.lib.cleanSource ./.;

          vendorSha256 = null;
        }
    EOF

    echo "use nix" >> .envrc
''
