#!/bin/sh

LOCATION=https://nixos.org/nix/install

if command -v wget; then
  wget "${LOCATION}" -O - | sh
elif command -v curl; then
  curl -L "${LOCATION}" | sh
else
  echo "I need cURL or wget to download Nix :("
  exit 1
fi
