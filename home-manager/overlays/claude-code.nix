# Pull claude-code from nixos-unstable so we get the latest release
# without upgrading the rest of the system.
inputs: final: _prev: {
  claude-code = (import inputs.nixpkgs-unstable {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  }).claude-code;
}
