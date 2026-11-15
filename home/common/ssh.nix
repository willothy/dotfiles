{ lib, pkgs, globalUserInfo, ... }:
let
  onepassword = import ./onepassword.nix { inherit pkgs globalUserInfo; };
in
{
  # Same rule for everything that reads SSH_AUTH_SOCK: local sessions get
  # 1Password, SSH sessions keep the forwarded agent.
  programs.fish.shellInit = ''
    if not set -q SSH_CONNECTION
      set -gx SSH_AUTH_SOCK "${onepassword.agentSocket}"
    end
  '';
  programs.bash.bashrcExtra = ''
    if [ -z "$SSH_CONNECTION" ]; then
      export SSH_AUTH_SOCK="${onepassword.agentSocket}"
    fi
  '';
  programs.zsh.envExtra = ''
    if [ -z "$SSH_CONNECTION" ]; then
      export SSH_AUTH_SOCK="${onepassword.agentSocket}"
    fi
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = lib.optional pkgs.stdenv.hostPlatform.isDarwin "${globalUserInfo.homeDir}/.orbstack/ssh/config";

    settings = {
      onepassword-agent = {
        header = "Match exec \"${onepassword.useLocalAgent}\"";
        IdentityAgent = ''"${onepassword.agentSocket}"'';
      };

      "*" = {
        ForwardAgent = true;
        SetEnv.TERM = "xterm-256color";
      };
    };
  };
}
