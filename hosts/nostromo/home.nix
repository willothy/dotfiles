{ pkgs, ... }:
let
  is_darwin = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
  onepassword_socket =
    if is_darwin then
      "/Users/willothy/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "/home/willothy/.1password/agent.sock"
  ;
  orbstack_ssh_config =
    if is_darwin then
      "Include /Users/willothy/.orbstack/ssh/config"
    else
      ""
  ;
in
{
  imports = [ ../../home/nixos ];

  home.stateVersion = "25.05";

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "x-scheme-handler/capy" = "capy.desktop";
    };
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = onepassword_socket;
  };

  programs.ssh =
    {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        # Pin the agent rather than following SSH_AUTH_SOCK, so ssh reaches
        # 1Password no matter what the desktop session exports.
        IdentityAgent = ''"${onepassword_socket}"'';
        ForwardAgent = true;
      };
      extraConfig = ''
        SetEnv TERM="xterm-256color"

        ${orbstack_ssh_config}
      '';
    };
}
