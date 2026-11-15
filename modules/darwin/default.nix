{ pkgs, globalUserInfo, ... }: {
  imports = [
    ./_1password.nix
  ];

  system.primaryUser = globalUserInfo.userName;

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;
}

