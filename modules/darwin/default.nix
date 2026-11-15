{ pkgs, globalUserInfo, ... }: {
  imports = [
    ./_1password.nix
    ./determinate.nix
  ];

  system.primaryUser = globalUserInfo.userName;

  users.users.${globalUserInfo.userName}.home = globalUserInfo.homeDir;

  security.pam.services.sudo_local.touchIdAuth = true;
}

