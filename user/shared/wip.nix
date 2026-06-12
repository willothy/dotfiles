# Things I need to refactor into their own modules
{ config, pkgs, globalUserInfo, lib, ... }:
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
      aliases = { 
        
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

      function git-recent
        set -l n 5
        if test (count $argv) -ge 1
          set n $argv[1]
        end

        git reflog show --all --format=%gs \
        | string match -r '^checkout: moving from .* to .*$' \
        | string replace -r '^checkout: moving from .* to (.*)$' '$1' \
        | string match -v -r '^[0-9a-f]{7,}$' \
        | awk 'seen[$0]++ == 0' \
        | head -n $n
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
      bind -M insert up history-prefix-search-backward
      bind -M insert down history-prefix-search-forward

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

    initExtra = ''
      # Function to check if a command/binary exists
      has() {
        command -v "$1" >/dev/null 2>&1
      }

      if has fnm; then
        eval "$(fnm env --use-on-cd --shell bash)"
      fi

      #if [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
      #    builtin source "$GHOSTTY_RESOURCES_DIR/shell-integration/bash/ghostty.bash"
      #fi
    '';
  };
  programs.zsh = {
    enable = true;
    inherit shellAliases;

    initContent = ''
      has() {
        command -v "$1" >/dev/null 2>&1
      }

      #if [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
      #    source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
      #fi

      if has fnm; then
        eval "$(fnm env --use-on-cd --shell zsh)"
      fi
    '';
  };

  programs.bat.enable = true;
}
