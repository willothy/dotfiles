{ pkgs, ... }:

{
  imports = [ ../../common ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # <nixpkgs> resolves through the flake registry to this flake's pinned
  # nixpkgs, not a separately-updated channel.
  nix.channel.enable = false;

  environment.systemPackages = with pkgs; [
    coreutils
    git
    gnutar

    gcc
    clang
    libclang
  ];

  programs.bash = {
    enable = true;
    completion.enable = true;
  };

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];

  environment.variables = {
    EDITOR = "vim";
  };

  programs.git = {
    enable = true;
    config = {
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libGL
      libGL.dev
      libxkbcommon
      egl-wayland
      expat
      wayland
      wayland.dev
      freetype
      freetype.dev

      libclang
      sqlite
      vulkan-headers
      vulkan-loader
      vulkan-tools
      ncurses

      libx11
      libxcursor
      libxi
      libxrandr
    ];
  };
}
