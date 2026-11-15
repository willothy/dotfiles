{ pkgs, globalUserInfo, ... }: {
  imports = [
    ./programs/_1password.nix
  ];

  system.primaryUser = "willothy";

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;
}

