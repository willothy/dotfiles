{ inputs, globalUserInfo, ... }: {
  home.file.".config/wezterm" = {
    source = "/${inputs.self}/configs/shared/wezterm";
    recursive = true;
  };

  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
