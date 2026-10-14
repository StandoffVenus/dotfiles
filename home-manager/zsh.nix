{ fetchFromGitHub }:

{
  enable = true;
  enableCompletion = true;
  syntaxHighlighting.enable = true;

  oh-my-zsh = {
    enable = true;
    theme = "amuse";
  };

  plugins = [
    {
      name = "rust";
      src = fetchFromGitHub {
        owner = "pkulev";
        repo = "zsh-rustup-completion";
        rev = "1.20.2";
        sha256 = "00w44np2vg86x5pss75fg0xp5m7c8rcrfj2l41231sqyqw762v1n";
      };
      file = "rustup.plugin.zsh";
    }
  ];
}
