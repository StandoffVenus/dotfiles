# Nixcord's discord.package overrides basePackage.override with a `source`
# argument that nixpkgs release-25.11's discord derivation doesn't accept
# (that arg was added later, upstream). Use nixpkgs-unstable's discord
# derivations instead so the override works.
inputs: final: _prev:
let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in {
  inherit (pkgs-unstable)
    discord
    discord-ptb
    discord-canary
    discord-development
    ;
}
