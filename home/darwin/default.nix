{ config, pkgs, globalUserInfo, lib, inputs, ... }:
{
  imports = [
    ./programs/neovim.nix
    ./programs/git.nix
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
    VISUAL = globalUserInfo.editorVisual;
    BROWSER = globalUserInfo.browser;
    PAGER = globalUserInfo.pager;

    SSH_AUTH_SOCK =
      if (pkgs.system == "aarch64-darwin") then
        "${globalUserInfo.homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      else
        "${globalUserInfo.homeDir}/.1password/agent.sock"
    ;
  };

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    maple-mono.NF
  ];

  programs.home-manager.enable = true;
}
