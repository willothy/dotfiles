{ pkgs, globalUserInfo }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
rec {
  agentSocket =
    if isDarwin then
      "${globalUserInfo.homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "${globalUserInfo.homeDir}/.1password/agent.sock";

  sshSign =
    if isDarwin then
      "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else
      "${pkgs._1password-gui}/bin/op-ssh-sign";

  # Exits 0 when this is a local session and 1Password's agent is running;
  # SSH sessions use whatever agent was forwarded to them instead.
  useLocalAgent = pkgs.writeShellScript "use-1password-agent" ''
    [ -z "$SSH_CONNECTION" ] && [ -S "${agentSocket}" ]
  '';
}
