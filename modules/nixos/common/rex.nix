{ inputs, config, globalUserInfo, ... }:
{
  imports = [ inputs.rex.nixosModules.default ];

  # The Rex server runs from boot, as me, so its panes get my shell and files.
  # Besides the local socket it joins the tailnet as its own device through
  # Rex's built-in Tailscale, at https://<host>-rex.<tailnet>.ts.net. The first
  # start prints a sign-in link (`rex server status`, `journalctl -u rex`).
  services.rex = {
    enable = true;
    user = globalUserInfo.userName;
    group = "users";
    tailscale = {
      enable = true;
      hostname = "${config.networking.hostName}-rex";
      # tagged nodes have no owner, so the tailnet's access rules decide who
      # connects (the Macs' Rex apps are tagged too)
      advertiseTags = [
        "tag:dev"
        "tag:linux"
      ];
      allowTailnetMembers = true;
    };
  };
}
