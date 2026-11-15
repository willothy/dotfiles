{ pkgs, globalUserInfo, ... }: {
  home.packages = with pkgs; [
    git-subrepo
  ];

  programs.git.signing = {
    key = globalUserInfo.sshPublicKey;
    signByDefault = true;
  };
}
