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

      homeManagerDir = "${home}/.config/home-manager";
      nixosDir       = "${home}/.config/nixos";
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
          ({ config, pkgs, ... }: {
            nixpkgs.config.allowUnfree = true;

            imports = [ inputs.nixcord.homeModules.nixcord ];

            programs = {
              home-manager.enable = true;

              ssh = {
                enable = true;
                settings = {
                  github-standoffvenus = {
                    HostName     = "github.com";
                    User         = "git";
                    Port         = 22;
                    IdentityFile = "${home}/.ssh/github_standoffvenus_ed25519";
                  };
                };

                # Stops warning from appearing
                enableDefaultConfig = false;
              };

              bash = {
                enable = true;

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

                  hm() {
                    case "''${1-}" in
                      edit)
                        "''${EDITOR:-vim}" "${homeManagerDir}/flake.nix"
                        ;;
                      # Only these accept --flake.
                      build|switch|news|instantiate|option)
                        home-manager "$@" --flake "${homeManagerDir}#${username}"
                        ;;
                      "")
                        echo "usage: hm <edit|switch|build|news|generations|...>" >&2
                        return 2
                        ;;
                      *)
                        home-manager "$@"
                        ;;
                    esac
                  }
                '';
              };

              nixcord = {
                enable = true;

                discord = {
                  enable                    = true;
                  krisp.enable              = true;
                  silenceNoModClientWarning = true;
                };
              };

              git = {
                enable = true;

                settings = {
                  init.defaultBranch = "main";

                  user = {
                    name  = "standoffvenus";
                    email = "liam.mueller315@gmail.com";
                  };

                  protocol = {
                    ssh.allow   = "always";
                    http.allow  = "never";
                    https.allow = "never";
                    git.allow   = "never";
                  }; 
                };
              };
            };

            home = {
              inherit username;

              stateVersion  = "25.11";
              homeDirectory = home;

              packages = with pkgs; [
                brave
                claude-code
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
