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

    # nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    # nixos-cosmic.url = "github:jerbaroo/nixos-cosmic/patch-1";
    nixos-cosmic.url = "github:willothy/nixos-cosmic";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, ... } @inputs:
    let
      system = "x86_64-linux";

      overlays = {
        sccache = import ./overlays/sccache.nix;
      };

      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
        };

        overlays = [
          overlays.sccache
        ];
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
            {
              nix.settings = {
                substituters = [ "https://cosmic.cachix.org/" ];
                trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
              };
            }
            inputs.nixos-cosmic.nixosModules.default
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
