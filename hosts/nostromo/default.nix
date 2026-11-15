{ inputs, config, pkgs, globalUserInfo, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./boot/default.nix
      ./hardware/default.nix
      ./services/xserver.nix
      ./services/audio.nix
      ./services/desktop.nix
      ../../modules/nixos/common/cli.nix
      ../../modules/nixos/common/virtualisation.nix
      ../../modules/nixos/common/desktop-apps.nix
      ../../modules/nixos/common/determinate.nix
    ];

  networking.hostName = "nostromo";

  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

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

  users.users.${globalUserInfo.userName} = {
    isNormalUser = true;
    description = globalUserInfo.fullName;
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" "i2c" "kvm" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ globalUserInfo.sshPublicKey ];
  };

  environment.systemPackages = with pkgs; [
    # secure boot
    sbctl

    # vulkan
    vulkan-loader
    vulkan-headers
    vulkan-validation-layers
    vulkan-tools

    capy
  ];

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

  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      AllowAgentForwarding = true;
      X11Forwarding = true;
    };
  };

  services.crucible-ci-runner-vms = {
    tokenFile = "/etc/github-runner/crucible.token";
    stateDirectory = "/var/lib/microvms";
    asAvailable.startAtBoot = true;
    compilerCacheSize = 20;
  };

  system.stateVersion = "25.05";
}
