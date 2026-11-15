{ inputs, ... }:
{
  imports = [ inputs.determinate.nixosModules.default ];

  # Keep `nixpkgs#…` resolving to this flake's nixpkgs, not FlakeHub's nixpkgs-weekly.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nix.settings = {
    extra-substituters = [ "https://install.determinate.systems" ];
    extra-trusted-public-keys = [ "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=" ];
  };
}
