{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    luajit
    luajitPackages.luarocks

    poetry
    poetryPlugins.poetry-plugin-export
    python312

    # go
    # clang
    rustup

    # protobuf

    # ruby (ugh)
    # ruby_3_3
  ];
}

