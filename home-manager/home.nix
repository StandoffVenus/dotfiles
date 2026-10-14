# macOS-specific configuration, layered on top of shared.nix.
{ inputs }:

{
  config,
  pkgs,
  lib,
  ...
}:

let
  initgo = pkgs.callPackage ./cp-shell.nix {
    shell-nix = ./go-shell.nix;
    envrc = ./minimal.envrc;
  };

  firefox-addons = inputs.nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.repos.rycee.firefox-addons;
in {
  home = {
    stateVersion = "22.05";

    sessionVariables = {
      EDITOR = "codium";
      LANG = "en_US.UTF-8";
      LIBRARY_PATH = "${pkgs.libiconv}/lib";

      # There are no channels; shell.nix files that `import <nixpkgs>`
      # get the same nixpkgs this configuration is built from.
      NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
    };

    shellAliases = {
      code = "codium";
      dira = "direnv allow .";
      gohome = "cd ${config.home.homeDirectory}/.config/home-manager";
      hm_rm = "hm remove-generations";
      initgo = "${initgo}/bin/cp-shell";
      l = "eza -1al";
      ls = "eza --group-directories-first";
    };

    packages = with pkgs; [
      awscli2
      bitwarden-cli
      claude-desktop
      # Docker CLI, with Colima as the daemon in place of Docker Desktop.
      colima
      delve
      docker
      eza
      gopls
      iterm2
      jq
      libiconv
      nodejs
      rectangle
      rustup
    ];
  };

  # Copies rather than symlinks .app bundles into ~/Applications, since
  # Spotlight and the Dock do not follow symlinks.
  targets.darwin = {
    linkApps.enable = false;
    copyApps.enable = true;
  };

  programs = {
    htop = import ./htop.nix { inherit config; };
    git.settings = import ./git.nix;
    zsh = import ./zsh.nix { inherit (pkgs) fetchFromGitHub; };

    direnv.enable = true;
    gpg.enable = true;

    firefox = {
      enable = true;
      profiles.liam = {
        id = 0;
        name = "Liam";
        isDefault = true;
        extensions.packages = with firefox-addons; [
          ublock-origin
          bitwarden
        ];
      };
    };

    vscodium.enable = true;
  };
}
