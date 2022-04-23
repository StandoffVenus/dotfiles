{
  enable = true;
  userName = "Liam Mueller";
  userEmail = "liam.mueller315@gmail.com";
  extraConfig = {
    pull = {
      rebase = false;
    };
    init = {
      defaultBranch = "main";
    };
    protocol = {
      http.allow = "never";
      https.allow = "never";
      git.allow = "never";
      ssh.allow = "always";
    };
  };
}
