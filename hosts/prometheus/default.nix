{ pkgs, globalUserInfo, ... }:

{
  imports = [
    ./disk.nix
    ./hardware-configuration.nix
    ../../modules/nixos/common/cli.nix
    ../../modules/nixos/common/virtualisation.nix
    ../../modules/nixos/common/desktop-apps.nix
  ];

  nixpkgs.config.allowUnfree = true;

  nix.settings.trusted-users = [ "@wheel" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "prometheus";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.amdgpu.initrd.enable = true;

  # No display manager: boot to a TTY and run `desktop` to start COSMIC.
  # Logging out tears the whole session down.
  services.desktopManager.cosmic.enable = true;
  environment.shellAliases.desktop = "start-cosmic";

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -S 120 /dev/%k"
  '';

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  users.users.${globalUserInfo.userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "docker" "libvirtd" "kvm" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [ globalUserInfo.sshPublicKey ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowAgentForwarding = true;
    };
  };

  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  system.stateVersion = "26.11";
}
