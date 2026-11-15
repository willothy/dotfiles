{ config, pkgs, globalUserInfo, lib, inputs, ... }:
{
  imports = [
    ../common
    ./programs/wezterm.nix
    ./programs/aerc.nix
    inputs._1password-shell-plugins.hmModules.default
  ];

  programs._1password-shell-plugins = {
    enable = true;
    plugins = with pkgs; [
      gh
      src-cli
      flyctl
    ];
  };

  home.username = globalUserInfo.userName;
  home.homeDirectory = globalUserInfo.homeDir;

  home.sessionVariables = {
    BROWSER = globalUserInfo.browser;
    PAGER = globalUserInfo.pager;
  };

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    maple-mono.NF
  ];
}
