{ config, pkgs, lib, ... }:

let
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
      discord;

  docker-desktop = with pkgs; (import ./docker-desktop-darwin.nix) {
    inherit stdenv;
    inherit undmg;
    inherit lib;
    fetchurl = builtins.fetchurl;
  };

  htop = (import ./htop.nix { inherit config; });
  git = import ./git.nix;
  vim = with pkgs; (import ./vim.nix {
    inherit vim_configurable;
    inherit vimPlugins;
    isDarwin = stdenv.isDarwin;
  });

  coc = with pkgs; import ./coc.nix {
    inherit stdenv;
    inherit writeTextFile;
  };

  darwin-packages = with pkgs; if stdenv.isDarwin then
    [
      iterm2
      rectangle
      docker-desktop
    ]
  else
    [];

  packages = with pkgs; [
    awscli2
    bitwarden-cli
    browsh
    discord
    docker
    exa
    gopls
    nodejs
    vim
  ] ++ darwin-packages;
in { 
  home = {
    username = "mule";
    homeDirectory = "/Users/mule";
    stateVersion = "22.05";

    sessionVariables = {
      EDITOR = "vim";
      LANG = "en_US.UTF-8";
      NIXPKGS_ALLOW_UNFREE = "1";
    };

    shellAliases = {
      hm = "home-manager -f $HOME/develop/env/home.nix";
      lx = "exa";
      vi = "vim"; # For butter fingers
    };

    # Creates ~/.vim/coc-settings.json symlink
    file.".vim/coc-settings.json".source = config.lib.file.mkOutOfStoreSymlink coc;

    inherit packages;
  };

  programs = {
    home-manager.enable = true;
    inherit htop;
    inherit git;

    zsh = {
      enable = true;
      enableCompletion = true;
      enableSyntaxHighlighting = true;
      oh-my-zsh = {
        enable = true;
        theme = "amuse";
      };
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
  };
}
