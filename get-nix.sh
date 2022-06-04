#!/bin/sh

set -e
LOCATION=https://nixos.org/nix/install
NIX_DARWIN=https://github.com/LnL7/nix-darwin/archive/master.tar.gz

NIX_EXISTS=0

# Check if the directory exists
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

# It's okay to reinstall nix-darwin since Nix modules
# should be idempotent
if [[ `uname` == "Darwin" ]]; then
    echo "Looks like you're on Darwin (Mac) - installing nix-darwin for you!"
    nix-build "${NIX_DARWIN}" -A installer
    ./result/bin/darwin-installer
    rm result
fi
