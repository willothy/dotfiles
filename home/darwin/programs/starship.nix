{ lib, ... }: {
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
