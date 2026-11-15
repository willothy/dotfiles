{ inputs, globalUserInfo, ... }: {
  home.file.".config/aerospace" = {
    source = "/${inputs.self}/configs/macos/aerospace";
    recursive = true;
  };
}

