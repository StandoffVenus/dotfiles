{ fetchFromGitHub }:

let
  fetch = fetchFromGitHub;
in {
  enable = true;
  enableCompletion = true;
  enableSyntaxHighlighting = true;

  oh-my-zsh = {
    enable = true;
    theme = "amuse";
  };

  initExtra = ''
    eval "$(direnv hook zsh)"
  '';

  plugins = [
    {
      name = "rust";
      src = fetch {
        owner = "pkulev";
        repo = "zsh-rustup-completion";
        rev = "1.20.2";
        sha256 = "00w44np2vg86x5pss75fg0xp5m7c8rcrfj2l41231sqyqw762v1n";
      };
      file = "rustup.plugin.zsh";
    }
  ];
}
