{ lib, pkgs, globalUserInfo, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  onepasswordSocket =
    if isDarwin then
      "${globalUserInfo.homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "${globalUserInfo.homeDir}/.1password/agent.sock";

  # Local sessions use 1Password's agent once it is running; SSH sessions keep
  # whatever agent was forwarded to them.
  useOnepasswordAgent = pkgs.writeShellScript "use-1password-agent" ''
    [ -z "$SSH_CONNECTION" ] && [ -S "${onepasswordSocket}" ]
  '';
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = lib.optional isDarwin "${globalUserInfo.homeDir}/.orbstack/ssh/config";

    settings = {
      onepassword-agent = {
        header = "Match exec \"${useOnepasswordAgent}\"";
        IdentityAgent = ''"${onepasswordSocket}"'';
      };

      "*" = {
        ForwardAgent = true;
        SetEnv.TERM = "xterm-256color";
      };
    };
  };
}
