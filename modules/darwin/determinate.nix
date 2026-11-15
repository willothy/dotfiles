{ inputs, globalUserInfo, ... }:
{
  # Nix itself comes from the Determinate installer; this hands its
  # configuration to Determinate Nixd instead of nix-darwin.
  imports = [ inputs.determinate.darwinModules.default ];

  determinateNix = {
    enable = true;

    customSettings.trusted-users = [ "root" "@admin" globalUserInfo.userName ];

    # Keep `nixpkgs#…` resolving to this flake's nixpkgs.
    registry.nixpkgs.flake = inputs.nixpkgs;

    determinateNixd.garbageCollector.strategy = "automatic";
  };
}
