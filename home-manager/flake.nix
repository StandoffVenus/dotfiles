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
            (import ./overlays/proton-ge9.nix)
            (import ./overlays/claude-desktop.nix)
          ];
        };

        modules = [
          (import ./shared.nix { inherit inputs username home; })
          ./modules/url-handlers.nix

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
                claude-desktop
                easyeffects
                guitarix
                heroic
                qpwgraph
                prismlauncher
                steam
              ];
            };

            # GE-Proton9-27 alongside it, for Fallout: New Vegas. See
            # overlays/proton-ge9.nix for why an older base is wanted.
            xdg.dataFile."Steam/compatibilitytools.d/GE-Proton9-27".source =
              pkgs.proton-ge9.steamcompattool;

            # See modules/url-handlers.nix for why these need declaring.
            xdg.urlHandlers = {
              # Sign-in returns to the app through a claude:// link.
              "com.anthropic.Claude.desktop" = {
                schemes = [ "claude" ];
                source  = "${pkgs.claude-desktop}/share/applications/com.anthropic.Claude.desktop";
              };
            };
          })
        ];
      };
    };
}
