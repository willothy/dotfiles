{ inputs, config, pkgs, lib, ... }:
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

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
    };
  };

  programs.git = {
    enable = true;
    lfs = {
      enable = true;
    };
    signing = {
      # key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuB3Fm5F9/qUWn2Ok7EXZc8OkKmvy6AHI+Wit0+XDiV";
      # signByDefault = true;
    };
    settings = {
      user = {
        name = "Will Hopkins";
        email = "willothyh@gmail.com";
      };
      init = {
        defaultBranch = "main";
      };
      color.pager = "yes";
      "gpg \"ssh\"" = {
        program =
          if (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") then
            "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
          else
            "${pkgs._1password-gui}/bin/op-ssh-sign"
        ;
      };
      gpg.format = "ssh";
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

    inherit shellAliases;
  };

  programs.zsh = {
    enable = true;
    inherit shellAliases;
  };

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


  programs.bat.enable = true;

  programs.atuin = {
    enable = true;
    #enableBashIntegration = true;
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

    # atuin owns Ctrl-R
    historyWidget.command = "";
  };

  programs.zoxide = {
    enable = true;
    #enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    #enableBashIntegration = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
    #enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.bottom = {
    enable = true;
  };

  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
    #enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = false;
    extensions = [ ];
    settings = {
      git_protocol = "ssh";
      aliases = { };
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      format = lib.concatStrings [
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_commit"
        "$git_status"
        "$git_state"
        "$\{custom.sesh\}"
        "$battery"
        "$nix_shell"
        "$rust"
        "$lua"
        "$python"
        "$nodejs"
        "$c"
        "$fill"
        "$shell"
        "$line_break"
        "$jobs"
        "$\{custom.vi_mode\}"
        "$character"
      ];
      hostname = {
        ssh_only = true;
        format = "[$hostname]($style):";
      };
      shell = {
        disabled = false;
        style = "blue";
      };
      fill = {
        symbol = "  ";
      };
      nix_shell = {
        impure_msg = "impure";
        pure_msg = "pure";
        unknown_msg = "unknown";
        format = "[$symbol$state( \($name\))]($style)";
        symbol = "󱄅 ";
      };
      directory = {
        truncation_length = 4;
        style = "#5de4c7";
      };
      git_branch = {
        style = "#89ddff";
        format = "on [$symbol](#8da3bf)[$branch(:$remote_branch)]($style)";
        only_attached = true;
      };
      git_commit = {
        style = "#89ddff";
      };
      git_status = {
        style = "#91b4d5";
        conflicted = "=";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕ $ahead_count$behind_count";
        up_to_date = "";
        untracked = "?";
        stashed = "\\$";
        modified = "!";
        renamed = "»";
        deleted = "✘";
        format = "[$all_status$ahead_behind]($style) ";
      };
      custom = {
        sesh = {
          style = "#5de4c7";
          command = "echo \"$SESH_NAME\"";
          when = " test \"$SESH_NAME\" != \"\" ";
          format = "\\[[$output]($style)\\] ";
        };
        vi_mode = {
          disabled = false;
          command = "echo $ZVM_MODE_PROMPT";
          when = " test \"$ZVM_MODE_PROMPT\" != \"\" ";
          format = "$output ";
        };
      };
      #battery = {
      #  display = {
      #    threshold = 40;
      #  };
      #};
      rust = {
        style = "red";
        format = "[$symbol]($style) ";
        symbol = "";
      };
      lua = {
        style = "blue";
        format = "[$symbol]($style) ";
        symbol = "󰢱 ";
      };
      nodejs = {
        style = "green";
        format = "[$symbol]($style) ";
      };
      c = {
        style = "149";
        format = "[$symbol]($style) ";
      };
      python = {
        symbol = "󰌠";
        style = "yellow";
        format = "[$symbol $virtualenv]($style) ";
      };
      jobs = {
        style = "blue";
        format = "[$number]($style)";
        disabled = true; # there's an issue with the char width of the symbol in zsh
        symbol_threshold = 0;
        number_threshold = 1;
      };
      line_break = {
        disabled = false;
      };
      character = {
        disabled = false;
        success_symbol = "[->](green)";
        error_symbol = "[->](red)";
        vimcmd_symbol = "[->](green)";
        vimcmd_visual_symbol = "[->](yellow)";
        # vimcmd_symbol = "[<-](green)";
        # vimcmd_visual_symbol = "[<-](yellow)";
      };
    };
  };
}
