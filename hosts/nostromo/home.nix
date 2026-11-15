{
  imports = [ ../../home/nixos ];

  home.stateVersion = "25.05";

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "x-scheme-handler/capy" = "capy.desktop";
    };
  };
}
