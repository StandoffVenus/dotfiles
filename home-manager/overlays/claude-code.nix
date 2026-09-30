# Pull claude-code from nixos-unstable so we get the latest release
# without upgrading the rest of the system.
#
# Unstable's package tracks upstream with a lag, so we also feed it the
# release manifest fetched straight from downloads.claude.ai. The package
# takes `manifest` as an argument and derives version, URL and checksum
# from it, so this is all that a version bump needs. Refresh it with:
#
#   curl -fsSL https://downloads.claude.ai/claude-code-releases/$(
#     curl -fsSL https://downloads.claude.ai/claude-code-releases/latest
#   )/manifest.zst.json -o overlays/claude-code-manifest.zst.json
inputs: final: _prev: {
  claude-code = (import inputs.nixpkgs-unstable {
    inherit (final.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  }).claude-code.override {
    manifest = final.lib.importJSON ./claude-code-manifest.zst.json;
  };
}
