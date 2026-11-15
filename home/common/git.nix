{ pkgs, globalUserInfo, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = globalUserInfo.fullName;
        inherit (globalUserInfo) email;
      };
      init = {
        defaultBranch = "main";
      };
      color.pager = "yes";
      "gpg \"ssh\"" = {
        program =
          if (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") then
            "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
          else
            "${pkgs._1password-gui}/bin/op-ssh-sign"
        ;
      };
      gpg.format = "ssh";
      pull = {
        rebase = true;
      };
    };
  };

  programs.gh = {
    enable = true;
    extensions = [ ];
    settings = {
      git_protocol = "ssh";
      aliases = { };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
    };
  };
}
