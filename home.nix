{ inputs, config, pkgs, ... }:
let
  shellAliases = {
    ll = "ls -l";
    la = "ls -a";
    ls = "eza -s type";
    lt = "eza --tree -s type";
    ".." = "cd ..";
    gs = "git status";
    gc = "git commit";
    ga = "git add";
    gaa = "git add --all";
    gau = "git add --update";
    v = "nvim";
    ":q" = "exit";
    pls = "sudo";
    #cd = "z";
  };
in
{
  home.username = "willothy";
  home.homeDirectory = "/home/willothy";
  home.stateVersion = "25.05";

  programs.git = {
    enable = true;
    userName = "Will Hopkins";
    userEmail = "willothyh@gmail.com";
    signing = {
      # key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuB3Fm5F9/qUWn2Ok7EXZc8OkKmvy6AHI+Wit0+XDiV";
      # signByDefault = true;
    };
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
      };
    };
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      color.pager = "yes";
      gpg.format = "ssh";
      # "gpg \"ssh\"" = {
      #   program = "${pkgs._1password-gui}/bin/op-ssh-sign";
      # };
      pull = {
        rebase = true;
      };
    };
  };

  programs.fish = {
    enable = true;
    inherit shellAliases;
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

      bind -e -M insert \t
      bind -M insert \t forward-word
      bind -M insert -k up history-prefix-search-backward
      bind -M insert -k down history-prefix-search-forward

      # if [ -n "$GHOSTTY_RESOURCES_DIR" ];
      #     source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
      # end

      if has fnm
        fnm env --use-on-cd --shell fish | source
      end
    '';
  };

  programs.bash = {
    enable = true;
    inherit shellAliases;
  };

  programs.zsh = {
    enable = true;
    inherit shellAliases;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
  };

  # lua/plugins/* gets autoloaded by Lazy, so I use this to
  # do required nix-specific setup.
  home.file.".config/nvim/plugin/nix.lua" =
    let
      platform_ext =
        if (builtins.match "darwin$" pkgs.system) == null then
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


  programs.bat.enable = true;

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      auto_sync = true;
      sync_frequency = "30m";
      sync = {
        record = true;
      };
      keymap_mode = "vim-insert";
      keymap_cursor = {
        emacs = "steady-block";
        vim_insert = "steady-bar";
        vim_normal = "steady-block";
      };
      style = "compact";
      inline_height = 12;
    };
    flags = [
      "--disable-up-arrow"
    ];
  };

  programs.fzf = {
    enable = true;
    # enableFishIntegration = true;
    # enableBashIntegration = true;
    # enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.bottom = {
    enable = true;
  };

  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.gh = {
    enable = true;
    extensions = [ ];
    settings = {
      git_protocol = "ssh";
      aliases = { };
    };
  };

  programs.ssh =
    let
      darwin = pkgs.system == "aarch64-darwin";
      socket =
        if darwin then
          "/Users/willothy/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        else
          "/home/willothy/.1password/agent.sock"
      ;
      orbstack =
        if darwin then
          "Include /Users/willothy/.orbstack/ssh/config"
        else
          ""
      ;
    in
    {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          host = "*";
          extraOptions.IdentityAgent = ''"${socket}"'';
          forwardAgent = true;
        };
      };
      extraConfig = ''
        SetEnv TERM="xterm-256color"

        ${orbstack}
      '';
    };
}
