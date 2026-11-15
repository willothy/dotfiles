{
  programs.fish = {
    enable = true;
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

      # Cat file if it's a file, or ls if it's a directory
      function cat
        if test -d $argv[1]
          ls $argv
        else
          command bat $argv
        end
      end

      bind -e -M insert \t
      bind -M insert \t forward-word
      bind -M insert up history-prefix-search-backward
      bind -M insert down history-prefix-search-forward

      fish_add_path $HOME/.local/bin
      fish_add_path $HOME/.cargo/bin
      fish_add_path $HOME/.bun/bin

      if has fnm
        fnm env --use-on-cd --shell fish | source
      end

      atuin hex init fish | source
    '';
  };

  programs.bash = {
    enable = true;

    initExtra = ''
      # Function to check if a command/binary exists
      has() {
        command -v "$1" >/dev/null 2>&1
      }

      if has fnm; then
        eval "$(fnm env --use-on-cd --shell bash)"
      fi
    '';
  };

  programs.zsh = {
    enable = true;

    initContent = ''
      has() {
        command -v "$1" >/dev/null 2>&1
      }

      if has fnm; then
        eval "$(fnm env --use-on-cd --shell zsh)"
      fi
    '';
  };
}
