{ pkgs, globalUserInfo, ... }: {
  home.packages = with pkgs; [
    git-subrepo
  ];

  programs.git = {
    enable = true;
    userName = globalUserInfo.fullName;
    userEmail = globalUserInfo.email;
    signing = {
      key = globalUserInfo.sshSigningKey;
      signByDefault = true;
    };
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
      };
    };
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      color.pager = "yes";
      gpg.format = "ssh";
      "gpg \"ssh\"" = {
        program =
          if (pkgs.system == "aarch64-darwin") then
            "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
          else
            "${pkgs._1password-gui}/bin/op-ssh-sign"
        ;
      };
      pull = {
        rebase = true;
      };
    };
  };
}
