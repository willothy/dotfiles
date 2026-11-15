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
}
