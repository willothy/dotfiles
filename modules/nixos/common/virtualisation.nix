{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    dnsmasq # req'd for DNS and DCHP in libvirt VMs
    docker
    docker-compose
  ];

  virtualisation.docker = {
    enable = true;
    # docker.socket is enabled, so the daemon starts on first use. Starting it
    # at boot put it on the critical path to graphical.target, dragging in
    # network-online.target and its ~5s wait for NetworkManager.
    enableOnBoot = false;
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.vhostUserPackages = with pkgs; [
      virtiofsd
    ];
  };
  systemd.services.virt-secret-init-encryption.enable = false;

  programs.virt-manager.enable = true;
}
