{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    luajit
    luajitPackages.luarocks

    poetry
    poetryPlugins.poetry-plugin-export
    python312

    rustup
  ];
}
