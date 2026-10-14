{
  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord.url = "github:4evy/nixcord";

    # Firefox add-ons, packaged by rycee.
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }:
    let
      arch     = "aarch64";
      os       = "darwin";
      system   = "${arch}-${os}";
      username = "mule";
      home     = "/Users/${username}";
    in {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (import ./overlays/claude-code.nix inputs)
            (final: _prev: {
              claude-desktop = final.callPackage ./claude-desktop-darwin.nix { };
            })
          ];
        };

        modules = [
          (import ./shared.nix { inherit inputs username home; })
          (import ./home.nix { inherit inputs; })
        ];
      };
    };
}
