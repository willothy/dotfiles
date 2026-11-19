{ inputs, config, pkgs, globalUserInfo, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./storage.nix
      ./snapshots.nix
      ./boot/default.nix
      ./hardware/default.nix
      ./services/xserver.nix
      ./services/audio.nix
      ./services/desktop.nix
      ../../modules/nixos/common/cli.nix
      ../../modules/nixos/common/virtualisation.nix
      ../../modules/nixos/common/desktop-apps.nix
      ../../modules/nixos/common/determinate.nix
      ../../modules/nixos/common/rex.nix
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
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" "i2c" "kvm" "userfaultfd" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ globalUserInfo.sshPublicKey ];
  };

  # /dev/userfaultfd for dev work, usable by members of this group.
  users.groups.userfaultfd = { };
  services.udev.extraRules = ''
    KERNEL=="userfaultfd", GROUP="userfaultfd", MODE="0660"
  '';

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

  # Local builds only use CPU the desktop isn't using.
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";

  # With only zram as swap, running out of memory thrashes the machine into a
  # hard freeze long before the kernel's OOM killer acts. earlyoom kills the
  # single largest process first (systemd-oomd would kill its whole cgroup,
  # e.g. the terminal or app that launched it).
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    extraArgs = [ "--avoid" "^(cosmic-comp|\\.cosmic-comp-wr|Xwayland|systemd|sshd)$" ];
  };

  # CI runners are intentionally off on this host: CI jobs on a workstation
  # once drove its load to 307 and hung it for six hours, and Will's
  # instruction is that nostromo takes no CI work. prometheus runs the pool.
  # crucible's desktop runner role is out of flake.nix with it.

  system.stateVersion = "25.05";
}
