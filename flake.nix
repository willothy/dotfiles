{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # stable-nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @inputs:
    let
      system = "x86_64-linux";

      config = {
        allowUnfree = true;
      };

      pkgs = import nixpkgs {
        inherit system;
        inherit config;
      };
    in
    {
      nixosConfigurations = {
        nostromo = nixpkgs.lib.nixosSystem {
          inherit pkgs;

          specialArgs = {
            inherit system;
            inherit inputs;
          };

          modules = [
            ./nixos/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                users.willothy = import ./home.nix;

                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs;
                };
              };
            }
          ];
        };
      };
    };
}
