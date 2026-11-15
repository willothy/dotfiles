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
    tokei
    procs
    rsync
    graphviz
    dig
    nix-du
    hyperfine
    terraform

    just
    act
    gnumake
    cmake
    pkg-config

    rustup

    luajit
    luajitPackages.luarocks

    sqlite
  ];
}
