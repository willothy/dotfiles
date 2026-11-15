{
  description = "NixOS and nix-darwin configurations for nostromo, prometheus and macbonk";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:willothy/lanzaboote/refind";

      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    crucible.url = "git+ssh://git@github.com/willothy/crucible";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager-darwin = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    onepassword-shell-plugins.url = "github:1Password/shell-plugins";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
  };

  outputs = { self, nixpkgs, home-manager, ... } @inputs:
    let
      system = "x86_64-linux";

      overlays = {
        refind = import ./overlays/refind.nix;
        capy = import ./overlays/capy.nix;
      };

      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
        };

        overlays = [
          overlays.refind
          overlays.capy
        ];
      };

      darwinSystem = "aarch64-darwin";

      darwinPkgs = import inputs.nixpkgs-darwin {
        system = darwinSystem;
        config.allowUnfree = true;
      };

      mkUserInfo = system: rec {
        userName = "willothy";
        fullName = "Will Hopkins";
        email = "willothyh@gmail.com";
        homeDir =
          if nixpkgs.lib.hasSuffix "darwin" system then
            "/Users/${userName}"
          else
            "/home/${userName}";
        editorVisual = "nvim -b";
        pager = "delta";
        browser = "brave";
        sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuB3Fm5F9/qUWn2Ok7EXZc8OkKmvy6AHI+Wit0+XDiV";
      };

      linuxUserInfo = mkUserInfo system;
      darwinUserInfo = mkUserInfo darwinSystem;

      linuxContext = {
        inherit inputs;
        globalUserInfo = linuxUserInfo;
      };

      darwinContext = {
        inputs = inputs // {
          _1password-shell-plugins = inputs.onepassword-shell-plugins;
        };
        globalUserInfo = darwinUserInfo;
      };
    in
    {
      nixosConfigurations = {
        nostromo = nixpkgs.lib.nixosSystem {
          inherit pkgs;

          specialArgs = linuxContext // { inherit system; };

          modules = [
            { disabledModules = [ "system/boot/loader/refind/refind.nix" ]; }
            ./modules/nixos/refind/default.nix
            ./hosts/nostromo
            inputs.determinate.nixosModules.default
            {
              # Keep `nixpkgs#…` resolving to this flake's nixpkgs, not FlakeHub's nixpkgs-weekly.
              nix.registry.nixpkgs.flake = inputs.nixpkgs;

              nix.settings = {
                extra-substituters = [ "https://install.determinate.systems" ];
                extra-trusted-public-keys = [ "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=" ];
              };
            }
            inputs.lanzaboote.nixosModules.lanzaboote
            inputs.crucible.nixosModules.ci-runner-desktop
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                users.${linuxUserInfo.userName} = import ./hosts/nostromo/home.nix;

                backupFileExtension = "backup";
                extraSpecialArgs = linuxContext;
              };
            }
          ];
        };

        prometheus = nixpkgs.lib.nixosSystem {
          specialArgs = linuxContext;

          modules = [
            inputs.disko.nixosModules.disko
            ./hosts/prometheus
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                users.${linuxUserInfo.userName} = import ./hosts/prometheus/home.nix;

                backupFileExtension = "backup";
                extraSpecialArgs = linuxContext;
              };
            }
          ];
        };
      };

      # `darwin-rebuild switch --flake .` and `home-manager switch --flake .`
      # find these through nix's packages.<system> fallback.
      packages.${darwinSystem} = {
        darwinConfigurations.macbonk = inputs.darwin.lib.darwinSystem {
          system = darwinSystem;
          pkgs = darwinPkgs;

          specialArgs = darwinContext;

          modules = [
            { system.configurationRevision = self.rev or self.dirtyRev or null; }
            ./hosts/macbonk
            ./modules/darwin
            ./modules/darwin/common
          ];
        };

        homeConfigurations.${darwinUserInfo.userName} = inputs.home-manager-darwin.lib.homeManagerConfiguration {
          pkgs = darwinPkgs;

          extraSpecialArgs = darwinContext;

          modules = [ ./hosts/macbonk/home.nix ];
        };
      };
    };
}
