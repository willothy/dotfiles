{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    curl
    wget
    unzip

    jq
    ripgrep
    fd
    hexyl
    fzf

    gnumake
    cmake
    pkg-config

    rustup

    luajit
    luajitPackages.luarocks

    sqlite
  ];
}
