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
  # Same rule for everything that reads SSH_AUTH_SOCK: local sessions get
  # 1Password, SSH sessions keep the forwarded agent.
  programs.fish.shellInit = ''
    if not set -q SSH_CONNECTION
      set -gx SSH_AUTH_SOCK "${onepasswordSocket}"
    end
  '';
  programs.bash.bashrcExtra = ''
    if [ -z "$SSH_CONNECTION" ]; then
      export SSH_AUTH_SOCK="${onepasswordSocket}"
    fi
  '';
  programs.zsh.envExtra = ''
    if [ -z "$SSH_CONNECTION" ]; then
      export SSH_AUTH_SOCK="${onepasswordSocket}"
    fi
  '';

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
