{ pkgs, ... }: {
  programs.aerc = {
    enable = true;
    extraAccounts = { };
    extraConfig = {
      compose = {
        editor = "nvim";
      };
    };
  };
}
