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
      fnvDir   = "/mnt/games/SteamLibrary/steamapps/common/Fallout New Vegas";

      # Same filesystem as fnvDir, reached via the /home mount rather than
      # /mnt, because MO2 and the prefix are addressed by that path.
      fnvCompatData = "${home}/Games/SteamLibrary/steamapps/compatdata/22380";
      mo2Dir        = "${fnvCompatData}/pfx/drive_c/Modding/MO2";
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

          ({ pkgs, ... }: let
            # Steam and steam-run each get a private /tmp by default, which
            # hides wine's server socket between them: a Nexus link then
            # starts a second MO2 instead of reaching the running one.
            steam = pkgs.steam.override { privateTmp = false; };
          in {
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

                # Re-applies the FNV 4GB patch, which Steam undoes whenever
                # it updates or verifies the game files.
                fnv4gb() (
                  cd "${fnvDir}" && ${steam.run}/bin/steam-run ./FalloutNVPatcher
                )
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
                # Audits/repairs the FNV + MO2 + SteamTinkerLaunch setup, whose
                # invariants Steam updates, the vanilla launcher and Proton
                # prefix rebuilds each quietly undo. See fnv-doctor.sh.
                (pkgs.writeShellApplication {
                  name = "fnv-doctor";
                  runtimeInputs = with pkgs; [ coreutils gnugrep gnused procps ];
                  # Reference copies of the NVSE plugin INIs. These are separate
                  # optional downloads on Nexus, absent from the main mod
                  # archives, and cannot be re-fetched without a login.
                  text = "FNV_INI_DIR=${./fnv}\n"
                    + builtins.readFile ./fnv-doctor.sh;
                })
                steam
              ];
            };

            # GE-Proton9-27 alongside it, for Fallout: New Vegas. See
            # overlays/proton-ge9.nix for why an older base is wanted.
            xdg.dataFile."Steam/compatibilitytools.d/GE-Proton9-27".source =
              pkgs.proton-ge9.steamcompattool;

            # See modules/url-handlers.nix for why these need declaring.
            xdg.urlHandlers = {
              # Nexus "Mod Manager Download" links, handled by MO2's own
              # nxmhandler.exe. SteamTinkerLaunch used to do this, but it ran
              # MO2 under bare wine with no Steam environment, which the Steam
              # build of FNV cannot launch from. Proton needs steam-run on
              # NixOS, and the two STEAM_COMPAT_* vars to find the game's
              # prefix.
              "mo2-nxm-handler.desktop" = {
                schemes = [ "nxm" "nxm-protocol" ];
                source  = pkgs.writeText "mo2-nxm-handler.desktop" ''
                  [Desktop Entry]
                  Type=Application
                  Name=Mod Organizer 2 (Nexus links)
                  Exec=${steam.run}/bin/steam-run env STEAM_COMPAT_CLIENT_INSTALL_PATH=${home}/.local/share/Steam STEAM_COMPAT_DATA_PATH=${fnvCompatData} ${pkgs.proton-ge9.steamcompattool}/proton run ${mo2Dir}/nxmhandler.exe %u
                  MimeType=x-scheme-handler/nxm;x-scheme-handler/nxm-protocol;
                  NoDisplay=true
                '';
              };

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
