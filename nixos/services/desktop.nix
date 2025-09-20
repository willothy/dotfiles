{ config, pkgs, ... }: {
  # services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
}
