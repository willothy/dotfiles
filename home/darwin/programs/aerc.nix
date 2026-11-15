{ pkgs, ... }: {
  # TUI email client
  programs.aerc = {
    enable = true;
    extraAccounts = {
      # Personal = { };
      # Work = { };
    };
    extraConfig = {
      compose = {
        editor = "nvim";
      };
    };
  };
}
