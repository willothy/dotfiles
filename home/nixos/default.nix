{ inputs, config, pkgs, lib, ... }:
{
  imports = [ ../common ];

  home.username = "willothy";
  home.homeDirectory = "/home/willothy";

  home.packages =
    with pkgs;
    let
      gdk = google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
        gke-gcloud-auth-plugin
      ]);
    in
    [
      gdk
    ];

  # programs.zed-editor = {
  #   enable = true;
  # };

  programs.git = {
    lfs = {
      enable = true;
    };
    signing = {
      # key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuB3Fm5F9/qUWn2Ok7EXZc8OkKmvy6AHI+Wit0+XDiV";
      # signByDefault = true;
    };
  };

  programs.fish = {
    enable = true;
    shellInitLast = ''
      set -g fish_greeting

      # Function to check if a command/binary exists
      function has
        command -v $argv[1] >/dev/null 2>&1
      end

      if set -q NVIM
        # Don't use vim bindings in Neovim terminal
      else
        fish_vi_key_bindings
        fish_vi_cursor

        set fish_cursor_default block
        set fish_cursor_insert line
        set fish_cursor_visual block
        set fish_vi_force_cursor 1
      end

      # Cat file if it's a file, or ls if it's a directory
      function cat
        if test -d $argv[1]
          ls $argv
        else
          command bat $argv
        end
      end

      # bind -e -M insert tab
      # bind -M insert tab forward-word
      bind -M insert up history-prefix-search-backward
      bind -M insert down history-prefix-search-forward

      fish_add_path $HOME/.local/bin
      fish_add_path $HOME/.cargo/bin
      fish_add_path "/home/willothy/.bun/bin"

      # if [ -n "$GHOSTTY_RESOURCES_DIR" ];
      #     source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
      # end

      if has fnm
        fnm env --use-on-cd --shell fish | source
      end
    '';
  };

  programs.tmux.enable = true;
  programs.tmux.extraConfig = ''
    setw -g mouse on

    set -g update-environment "DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_CONNECTION WINDOWID XAUTHORITY"
  '';

  programs.bash = {
    enable = true;
    package = pkgs.bashInteractive;
  };

  programs.zsh.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # nvim-treesitter's main branch builds parsers by shelling out to the CLI.
    extraPackages = [
      pkgs.tree-sitter
      pkgs.sqlite
    ];
  };

  # home-manager generates an init.lua from the provider settings above and
  # takes ownership of ~/.config/nvim/init.lua, moving ours to init.lua.backup
  # on every activation. The config in ~/.config/nvim is the source of truth;
  # home-manager only supplies the package.
  xdg.configFile."nvim/init.lua".enable = lib.mkForce false;

  home.file.".config/ghostty/config".source = ../../configs/ghostty/config;

  # lua/plugins/* gets autoloaded by Lazy, so I use this to
  # do required nix-specific setup.
  home.file.".config/nvim/plugin/nix.lua" =
    let
      platform_ext =
        if (builtins.match "darwin$" pkgs.stdenv.hostPlatform.system) == null then
          "so"
        else
          "dylib"
      ;
    in
    {
      text = ''
        -- set sqlite library path for sqlite.lua
        vim.g.sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3.${platform_ext}"

        return {}
      '';
    };

  programs.gh.gitCredentialHelper.enable = false;
}
