{ pkgs, ... }: {
  # TODO: Move these into optional config. I don't want them on servers.
  environment.systemPackages = with pkgs; [
    # Utilities
    bottom
    tokei # Line count
    procs # Modern ps
    rm-improved # Modern rm with trash and more
    rsync # File transfer
    rclone # "rsync for cloud storage"
    ngrok # Expose a local web server to the internet
    graphviz # Dot

    # Monitoring
    bandwhich # Network monitor
    ctop # Container metrics
    btop # Resource monitor
    gping # Ping, but with a graph
    dig
    duf # Disk usage TUI
    nix-du # du for /nix/store

    # Build Tools & Runners
    just # Task runner
    ccache
    act # Run GitHub actions locally

    # Work & Development
    hyperfine # Benchmarks
    httpie # CLI HTTP client
    lazydocker # Docker TUI
    terraform # Infra as code

    # Official Third-Party CLIs
    gh # GitHub
  ];
}
