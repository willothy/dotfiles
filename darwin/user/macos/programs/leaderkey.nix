{ inputs, globalUserInfo, ... }: {
  home.file."Library/Application Support/Leader Key" = {
    source = "/${inputs.self}/configs/macos/leaderkey";
    recursive = true;
  };
}

