{ pkgs, globalUserInfo, ... }: {
  home.packages = with pkgs; [
    git-subrepo
  ];

  programs.git.signing = {
    key = globalUserInfo.sshSigningKey;
    signByDefault = true;
  };
}
