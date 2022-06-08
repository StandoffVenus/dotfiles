#!/bin/sh

set -e
LOCATION=https://nixos.org/nix/install

NIX_CHANNEL_PREFIX=https://nixos.org/channels
NIX_CHANNEL_VERSION=22.05
NIX_CHANNEL_STABLE=${NIX_CHANNEL_PREFIX}/nixpkgs-${NIX_CHANNEL_VERSION}
if [[ `uname` == "Darwin" ]]; then
  NIX_CHANNEL_STABLE=${NIX_CHANNEL_STABLE}-darwin
fi

# Check if the directory exists
NIX_EXISTS=0
if [ -d "/nix" ]; then
    # See if the directory is empty if it exists 
    if [ ! -z "$(ls -A /nix)" ]; then
       NIX_EXISTS=1 
    fi
fi

# Conditionally install Nix
if [ ${NIX_EXISTS} = 0 ]; then
    if command -v wget; then
      wget "${LOCATION}" -O - | sh
    elif command -v curl; then
      curl -L "${LOCATION}" | sh
    else
      echo "I need cURL or wget to download Nix :("
      exit 1
    fi
else
    echo "Looks like Nix is already installed; won't try to install again."
fi

addNixChannel() {
	echo "Adding Nix channel | $2 -> $1"
	nix-channel --add $1 $2
}
addNixChannel "${NIX_CHANNEL_STABLE}" nixpkgs

echo "Updating Nix channels..."
nix-channel --update
