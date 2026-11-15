{ pkgs, globalUserInfo, ... }: {
  imports = [
    ../../common
    ./cli-tools.nix
    ./languages.nix
  ];

  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [ "@admin" globalUserInfo.userName ];
  };

  programs._1password-cli.enable = true;

  environment.shells = with pkgs; [ zsh fish bash ];

  environment.variables = {
    LANG = "en_US.UTF-8";
  };
}
