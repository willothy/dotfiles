{ self, inputs, system }:
let
  inherit (inputs) darwin;
  nixpkgs = inputs.nixpkgs-darwin;
  home-manager = inputs.home-manager-darwin;

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;

    overlays = [
      (import ../overlays/spider-cli.nix)
      (import ../overlays/bufbuild.nix)
    ];
  };

  globalConfig = {
    system.configurationRevision = self.rev or self.dirtyRev or null;
  };

  globalUserInfo = rec {
    userName = "willothy";
    fullName = "Will Hopkins";
    email = "willothyh@gmail.com";
    homeDir =
      if (system == "aarch64-darwin") then
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

  flakeContext = {
    inputs = inputs // {
      _1password-shell-plugins = inputs.onepassword-shell-plugins;
    };
    inherit globalUserInfo;
  };
in
{
  darwinConfigurations = {
    macbonk = darwin.lib.darwinSystem {
      inherit system pkgs;

      specialArgs = flakeContext;

      modules = [
        globalConfig
        ./hosts/macos
        ./system/macos
        ./system/shared
      ];
    };
  };

  homeConfigurations = {
    willothy = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = flakeContext;

      modules = [
        ./user/shared
        ./user/macos
      ];
    };
  };
}
