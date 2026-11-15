{ pkgs, inputs, globalUserInfo, ... }: {
  home.file.".hammerspoon" = {
    recursive = true;
    source = "/${inputs.self}/configs/macos/hammerspoon";
  };
}




