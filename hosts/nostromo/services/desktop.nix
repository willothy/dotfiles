{ config, pkgs, ... }: {
  services.desktopManager.gnome.enable = false;

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # cosmic enables gnome-keyring, which defaults gcr-ssh-agent on. That agent
  # holds no keys but claims SSH_AUTH_SOCK, so 1Password never gets used.
  # gnome-keyring itself stays enabled for cosmic's secret store.
  services.gnome.gcr-ssh-agent.enable = false;

  environment.systemPackages = with pkgs; [
    cosmic-store
    cosmic-ext-applet-caffeine
    cosmic-ext-applet-external-monitor-brightness
    cosmic-ext-tweaks

    wayland
    egl-wayland
    expat
    fontconfig
    freetype
    freetype.dev
    libxkbcommon
    libGL
    pkg-config

    libx11
    libxcursor
    libxi
    libxrandr

    ddcutil
  ];
}
