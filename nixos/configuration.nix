{ inputs, config, pkgs, stable, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./boot/default.nix
      ./hardware/default.nix
      ./services/xserver.nix
      ./services/audio.nix
      ./services/desktop.nix
      ./services/sccache.nix
    ];

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  networking.hostName = "nostromo"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users.willothy = {
    isNormalUser = true;
    description = "Will Hopkins";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [

    ];
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    # I will go insane without this
    (vim_configurable.customize {
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ vim-nix vim-lastplace ];
        opt = [ ];
      };
      vimrcConfig.customRC = ''
        filetype plugin indent on
        syntax on

        set shiftwidth=2
        set tabstop=2
        set expandtab

        set showtabline=3
        set scrolloff=10

        set number relativenumber

        set nowrap hlsearch incsearch showmode

        set clipboard=unnamedplus
      '';
    })

    coreutils

    # usually need right away
    curl
    wget
    git
    unzip
    gnutar

    # build essentials
    gnumake
    cmake
    gcc
    pkg-config
    rustup
    nodejs
    python312
    sccache

    luajit
    luajitPackages.luarocks
    lua-language-server
    stylua

    # dev essentials
    docker
    docker-compose

    # libraries
    sqlite
    libclang
    clang

    # cli tools
    jq
    ripgrep
    fd
    hexyl
    fzf

    # terminal emulator
    ghostty

    nautilus

    # wayland clipboard fix
    wl-clipboard
    # wayclip
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.bash.enable = true;

  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs._1password-gui.polkitPolicyOwners = [ "willothy" ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libclang
      sqlite
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
  };

  programs.git = {
    enable = true;
    config = {
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
  programs.hyprland.xwayland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

  environment.variables = {
    EDITOR = "vim";
  };

  environment.shells = with pkgs; [
    bash
    zsh
    fish
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
