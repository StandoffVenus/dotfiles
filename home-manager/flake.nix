{
  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord.url = "github:4evy/nixcord";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    nixcord,
    ...
  }:
    let
      arch     = "x86_64";
      os       = "linux";
      system   = "${arch}-${os}";
      username = "kaiser";
      hostname = "kaiser_nixos";
      home     = "/home/${username}";

      nixosDir = "${home}/.config/nixos";
    in {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (import ./overlays/claude-code.nix inputs)
          ];
        };

        modules = [
          (import ./shared.nix { inherit inputs username home; })

          ({ pkgs, ... }: {
            programs.bash = {
              # Use `nixos boot`, not `nixos switch`, for release upgrades:
              # switch mutates the running system and can fail halfway.
              # 26.05 moved dbus to dbus-broker, which cannot be swapped
              # under a live session.
              initExtra = ''
                nixos() {
                  case "''${1-}" in
                    edit)
                      "''${EDITOR:-vim}" "${nixosDir}/flake.nix"
                      ;;
                    # Neither activates nor touches the bootloader.
                    build|dry-build|eval|repl|list-generations)
                      nixos-rebuild "$@" --flake "${nixosDir}#${hostname}"
                      ;;
                    "")
                      echo "usage: nixos <edit|switch|boot|test|build|...>" >&2
                      return 2
                      ;;
                    *)
                      sudo nixos-rebuild "$@" --flake "${nixosDir}#${hostname}"
                      ;;
                  esac
                }
              '';
            };

            home = {
              stateVersion = "25.11";

              packages = with pkgs; [
                easyeffects
                guitarix
                heroic
                qpwgraph
                prismlauncher
                steam
              ];
            };
          })
        ];
      };
    };
}
