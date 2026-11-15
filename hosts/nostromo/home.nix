{ globalUserInfo, ... }:
let
  onepassword_socket = "${globalUserInfo.homeDir}/.1password/agent.sock";
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


      '';
    };
}
