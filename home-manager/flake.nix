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
      home     = "/home/${username}";

      homeManagerDir = "${home}/.config/home-manager";
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
                shellAliases = {
                  nix_rebuild = ''
                    sudo nixos-rebuild switch
                  '';

                  hm_edit = ''
                    "''${EDITOR:-vim}" "${homeManagerDir}/flake.nix"
                  '';

                  hm_switch = ''
                    nix run home-manager/release-26.05 -- \
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
