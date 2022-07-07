{
  config,
  pkgs,
  lib,
  ...
}:

let
  username = "mule";
  home-directory = if pkgs.stdenv.isDarwin then
      "/Users/${username}"
    else
      "/home/${username}";

  current-directory = builtins.toString ./.;
  go-init = import ./cp-shell.nix {
    writeShellScriptBin = pkgs.writeShellScriptBin;
    shell-nix = ./go-shell.nix;
    envrc = ./minimal.envrc;
  };

  my_firefox = with pkgs; if stdenv.isDarwin then
      (import ./firefox-darwin.nix) {
        inherit stdenv;
        inherit undmg;
        fetchurl = builtins.fetchurl;
      }
    else
      firefox;

  nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
    inherit pkgs;
  };
  firefox-addons = nur.repos.rycee.firefox-addons;

  rectangle = with pkgs; (import ./rectangle-darwin.nix) {
    inherit stdenv;
    inherit undmg;
    fetchurl = builtins.fetchurl;
  };

  discord = with pkgs; if stdenv.isDarwin then
      (import ./discord-darwin.nix) {
        inherit stdenv;
        inherit undmg;
        fetchurl = builtins.fetchurl;
      }
    else
      pkgs.discord;

  docker-desktop = with pkgs; (import ./docker-desktop-darwin.nix) {
    inherit stdenv;
    inherit undmg;
    inherit lib;
    fetchurl = builtins.fetchurl;
  };

  htop = (import ./htop.nix { inherit config; });
  git = import ./git.nix;
  zsh = with pkgs; import ./zsh.nix { inherit fetchFromGitHub; };

  darwin-packages = with pkgs; if stdenv.isDarwin then
    [
      iterm2
      rectangle
      docker-desktop
      libiconv
    ]
  else
    [];

  packages = with pkgs; [
    awscli2
    bitwarden-cli
    delve
    direnv
    discord
    docker
    exa
    jq
    gopls
    nodejs
    rustup
    spotify-tui
  ] ++ darwin-packages;
in {
  home = {
    inherit username;
    homeDirectory = home-directory;
    stateVersion = "22.05";

    sessionVariables = rec {
      EDITOR = "code";
      LANG = "en_US.UTF-8";
      NIXPKGS_ALLOW_UNFREE = "1";
      LIBRARY_PATH = if pkgs.stdenv.isDarwin then "${pkgs.libiconv}/lib" else "";
    };

    shellAliases = {
      code = "codium";
      dira = "direnv allow .";
      gohome = "cd ${current-directory}";
      hm   = "home-manager -f ${current-directory}/home.nix";
      hm_rm = "hm remove-generations";
      initgo = "sh ${go-init}/bin/cp-shell";
      l    = "exa -1al";
      ls   = "exa --group-directories-first";
    };

    file."Applications/home-manager".source = let
      apps = pkgs.buildEnv {
        name = "home-manager-applications";
        paths = config.home.packages;
        pathsToLink = "/Applications";
      };
      in lib.mkIf pkgs.stdenv.targetPlatform.isDarwin "${apps}/Applications";

    inherit packages;
  };

  programs = {
    home-manager.enable = true;
    inherit htop;
    inherit git;
    inherit zsh;

    direnv = {
      enable = true;
    };

    gpg = {
      enable = true;
    };
    
    firefox = {
      enable = true;
      package = my_firefox;
      extensions = with firefox-addons; [
        ublock-origin
        bitwarden
      ];
      profiles = {
        liam = {
          id = 0;
          name = "Liam";
          isDefault = true;
        };
      };
    };

    vscode = {
      enable = true;
      package = pkgs.vscodium;
    };
  };
}
