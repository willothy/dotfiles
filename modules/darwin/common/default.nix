{ pkgs, globalUserInfo, ... }: {
  imports = [ ../../common ];

  programs._1password-cli.enable = true;

  environment.shells = with pkgs; [ zsh fish bash ];

  environment.variables = {
    LANG = "en_US.UTF-8";
  };
}
