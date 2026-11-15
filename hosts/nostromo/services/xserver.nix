{ config, pkgs, ... }: {
  services.xserver.enable = true;

  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "caps:swapescape";
  };

  console.useXkbConfig = true;
}
