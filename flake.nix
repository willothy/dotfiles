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
    # nixos-cosmic.url = "github:willothy/nixos-cosmic";

    flake-utils.url = "github:numtide/flake-utils";

    lanzaboote = {
      # url = "github:nix-community/lanzaboote/v0.4.2";
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

    # refindgen.url = "github:willothy/refindgen";

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
        docutils-pin = import ./overlays/docutils-pin.nix;
        pytest-bs = import ./overlays/pytest-timeout-no-tests.nix;
        capy = import ./overlays/capy.nix;
      };

      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
        };

        overlays = [
          overlays.refind
          overlays.docutils-pin
          overlays.pytest-bs
          overlays.capy
          # inputs.refindgen.overlays.default
        ];
      };

      darwinSystem = "aarch64-darwin";

      darwinPkgs = import inputs.nixpkgs-darwin {
        system = darwinSystem;
        config.allowUnfree = true;

        overlays = [
          (import ./overlays/spider-cli.nix)
          (import ./overlays/bufbuild.nix)
        ];
      };

      globalUserInfo = rec {
        userName = "willothy";
        fullName = "Will Hopkins";
        email = "willothyh@gmail.com";
        homeDir =
          if (darwinSystem == "aarch64-darwin") then
            "/Users/${userName}"
          else
            "/home/${userName}";
        confDir = "~/.dotfiles";
        editor = "nvim";
        editorVisual = "nvim -b";
        pager = "delta";
        terminal = "wezterm";
        browser = "brave";
        # Public key, obviously
        sshSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuB3Fm5F9/qUWn2Ok7EXZc8OkKmvy6AHI+Wit0+XDiV";
      };

      darwinContext = {
        inputs = inputs // {
          _1password-shell-plugins = inputs.onepassword-shell-plugins;
        };
        inherit globalUserInfo;
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
                # substituters = [ "https://cosmic.cachix.org/" ];
                # trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
              };
              disabledModules = [ "system/boot/loader/refind/refind.nix" ];
            }
            ./modules/nixos/refind/default.nix
            # inputs.refindgen.nixosModules.default
            # inputs.nixos-cosmic.nixosModules.default
            ./hosts/nostromo
            inputs.lanzaboote.nixosModules.lanzaboote
            inputs.crucible.nixosModules.ci-runner-desktop
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                users.willothy = import ./hosts/nostromo/home.nix;

                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs;
                };
              };
            }
          ];
        };

        prometheus = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };

          modules = [
            inputs.disko.nixosModules.disko
            ./hosts/prometheus
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                users.willothy = import ./hosts/prometheus/home.nix;

                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs;
                };
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

        homeConfigurations.willothy = inputs.home-manager-darwin.lib.homeManagerConfiguration {
          pkgs = darwinPkgs;

          extraSpecialArgs = darwinContext;

          modules = [ ./hosts/macbonk/home.nix ];
        };
      };
    };
}
