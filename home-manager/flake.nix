{
  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned before commit 359646d, which requires lib.types.json
    # (not present in nixpkgs release-25.11's lib).
    nixcord.url = "github:4evy/nixcord/e6fd912d20acd25efd24f76514db8459a57c55dd";
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
      home     = "/home/${username}";

      homeManagerDir = "${home}/.config/home-manager";
    in {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (import ./overlays/claude-code.nix inputs)
            (import ./overlays/discord.nix inputs)
          ];
        };

        modules = [
          ({ config, pkgs, ... }: {
            nixpkgs.config = {
              allowUnfree = true;
              permittedInsecurePackages = [
                "electron-39.8.10"
              ];
            };

            imports = [ inputs.nixcord.homeModules.nixcord ];

            programs = {
              home-manager.enable = true;

              bash = {
                enable = true;
                shellAliases = {
                  nix_rebuild = ''
                    sudo nixos-rebuild switch
                  '';

                  hm_edit = ''
                    "''${EDITOR:-vim}" "${homeManagerDir}/flake.nix"
                  '';

                  hm_switch = ''
                    nix run home-manager/release-25.11 -- \
                      switch \
                        --flake "${homeManagerDir}#${username}"
                  '';
                };
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
