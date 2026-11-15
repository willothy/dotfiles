{ inputs, config, globalUserInfo, ... }:
{
  imports = [ inputs.rex.nixosModules.default ];

  # The Rex server runs from boot, as me, so its panes get my shell and files.
  # Besides the local socket it joins the tailnet as its own device through
  # Rex's built-in Tailscale, at https://<host>-rex.<tailnet>.ts.net. The first
  # start prints a sign-in link (`rex server status`, `journalctl -u rex`);
  # only the account that signs it in can connect.
  services.rex = {
    enable = true;
    user = globalUserInfo.userName;
    group = "users";
    tailscale = {
      enable = true;
      hostname = "${config.networking.hostName}-rex";
    };
  };
}
