{ inputs, globalUserInfo, ... }:
let
  port = 7297;
in
{
  imports = [ inputs.rex.nixosModules.default ];

  # The Rex server runs from boot, as me, so its panes get my shell and files.
  # Reachable on the local socket, and over the tailnet through this host's
  # tailscaled, which admits only my own Tailscale account.
  services.rex = {
    enable = true;
    user = globalUserInfo.userName;
    group = "users";
    extraListen = [ "tailnet://:${toString port}" ];
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
}
