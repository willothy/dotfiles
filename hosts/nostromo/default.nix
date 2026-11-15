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
      # ./services/sccache.nix
      ../../modules/nixos/common/cli.nix
      ../../modules/nixos/common/virtualisation.nix
      ../../modules/nixos/common/desktop-apps.nix
    ];

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
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" "i2c" "kvm" ];
    packages = with pkgs; [

    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuB3Fm5F9/qUWn2Ok7EXZc8OkKmvy6AHI+Wit0+XDiV"
    ];
  };

  environment.systemPackages = with pkgs; [
    # secure boot
    sbctl

    # vulkan
    vulkan-loader
    vulkan-headers
    vulkan-validation-layers
    vulkan-tools

    # (callPackage ../../packages/helium-browser.nix { })

    capy
  ];


  # environment.variables.LD_LIBRARY_PATH =
  #   let
  #     libs = with pkgs; [
  #       libclang
  #       sqlite
  #       vulkan-headers
  #       vulkan-loader
  #       vulkan-tools
  #       ncurses
  #
  #       wayland
  #       egl-wayland
  #       expat
  #       fontconfig
  #       freetype
  #       freetype.dev
  #       libxkbcommon
  #       libGL
  #       pkg-config
  #
  #       libx11
  #       libxcursor
  #       libxi
  #       libxrandr
  #     ];
  #     libPath = pkgs.lib.makeLibraryPath libs;
  #
  #   in
  #   "${libPath}"
  # ;

  programs.vscode = {
    enable = true;
    defaultEditor = false;
    extensions = with pkgs.vscode-extensions; [
      github.copilot
      github.copilot-chat
      rust-lang.rust-analyzer
      eamodio.gitlens
      usernamehw.errorlens
      vscodevim.vim
    ];
  };

  # environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;


  services.tailscale = {
    enable = true;
    # Allow this machine to *use* Tailscale routing features (e.g. connect to
    # subnet routers or exit nodes) without advertising routes itself.
    # "client" = can consume routes
    # "server" = can advertise routes (subnet router)
    # "none"   = disable routing features entirely
    useRoutingFeatures = "client";
  };

  services.resolved.enable = true;
  networking.nameservers = [ "192.168.1.1" ];

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      AllowAgentForwarding = true;

      # If you want X11 forwarding for GUI apps over SSH:
      X11Forwarding = true;
    };
  };

  services.crucible-ci-runner-vms = {
    tokenFile = "/etc/github-runner/crucible.token";
    stateDirectory = "/var/lib/microvms";
    asAvailable.startAtBoot = true;
    compilerCacheSize = 20;
  };

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
