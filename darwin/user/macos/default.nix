{ pkgs, globalUserInfo, ... }: {
  imports = [
    ./programs/yabai.nix
    ./programs/hammerspoon.nix
    ./programs/aerospace.nix
    ./programs/leaderkey.nix
  ];
}
