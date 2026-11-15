{ pkgs, ... }: {
  # TODO: Move these into optional config. I don't want them on servers.
  environment.systemPackages = with pkgs; [
    # Essentials
    curl
    wget
    unzip

    # Utilities
    bottom
    jq
    ripgrep
    fd
    hexyl # Hex editor
    fzf
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
    # dogdns # Modern dig replacement
    duf # Disk usage TUI
    nix-du # du for /nix/store

    # Build Tools & Runners
    just # Task runner
    gnumake
    cmake
    ccache
    pkg-config
    act # Run GitHub actions locally

    # Work & Development
    hyperfine # Benchmarks
    httpie # CLI HTTP client
    lazydocker # Docker TUI
    terraform # Infra as code

    # Official Third-Party CLIs
    # turso-cli # turso
    # awscli2 # AWS
    gh # GitHub
  ];
}
