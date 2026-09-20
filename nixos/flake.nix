{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }:
    let
      hostname = "kaiser_nixos";
    in {
      # Rebuild with:
      #   sudo nixos-rebuild switch --flake ~/.config/nixos#${hostname}
      #
      # `system` is intentionally omitted; hardware-configuration.nix sets
      # nixpkgs.hostPlatform, which serves the same purpose.
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
        ];
      };
    };
}
