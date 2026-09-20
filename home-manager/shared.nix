# Home Manager configuration common to every machine.
#
# Machine-specific flakes import this and add their own packages, shell
# functions and stateVersion. Options declared here use merging types
# (home.packages is a list, programs.bash.initExtra is lines), so a
# machine can extend them without overriding what is set below.
{ inputs, username, home }:

{ pkgs, ... }:

let
  homeManagerDir = "${home}/.config/home-manager";
in {
  imports = [ inputs.nixcord.homeModules.nixcord ];

  nixpkgs.config.allowUnfree = true;

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

      initExtra = ''
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

    homeDirectory = home;

    packages = with pkgs; [
      brave
      claude-code
    ];
  };
}
