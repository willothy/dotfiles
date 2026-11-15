{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    poetry
    poetryPlugins.poetry-plugin-export
    python312
  ];
}
