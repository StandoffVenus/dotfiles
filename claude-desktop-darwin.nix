# Claude Desktop, straight from Anthropic's macOS release feed: the same
# universal zip the app's own updater and the Homebrew cask download.
#
# The app normally updates itself (Squirrel/ShipIt), which cannot work
# from the read-only Nix store, so the release is pinned in
# claude-desktop-darwin.json instead. Refresh it with:
#
#   url=$(curl -fsSL https://downloads.claude.ai/releases/darwin/universal/RELEASES.json \
#     | jq -r '.currentRelease as $v | .releases[] | select(.version == $v).updateTo.url')
#   jq -n --arg url "$url" --arg sha256 "$(nix-prefetch-url "$url")" \
#     '{version: ($url | split("/")[-2]), $url, $sha256}' > claude-desktop-darwin.json
{ stdenv, fetchurl, unzip, lib }:

let
  release = lib.importJSON ./claude-desktop-darwin.json;
in stdenv.mkDerivation rec {
  pname = "Claude";
  inherit (release) version;

  buildInputs = [ unzip ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];

  src = fetchurl {
    name = "claude-${version}.zip";
    inherit (release) url sha256;
  };

  installPhase = ''
    mkdir -p "$out/Applications"
    cp -R Claude.app "$out/Applications"
  '';

  meta = with lib; {
    description = "Claude";
    homepage = "https://claude.ai";
    license = licenses.unfree;
    platforms = platforms.darwin;
  };
}
