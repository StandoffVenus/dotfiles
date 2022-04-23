let
  pkgs = import <nixpkgs> { };
in with pkgs; import ./coc.nix {
  inherit stdenv;
  mkOutOfStoreSymlink = mkOutOfStoreSymlink;
  inherit writeTextFile;
}
