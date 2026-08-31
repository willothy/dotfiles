{ config, pkgs, ... }: {
  # services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = false;

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

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

    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr

    ddcutil
  ];
}
