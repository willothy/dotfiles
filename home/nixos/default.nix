{ inputs, config, pkgs, lib, globalUserInfo, ... }:
{
  imports = [ ../common ];

  home.username = globalUserInfo.userName;
  home.homeDirectory = globalUserInfo.homeDir;

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

  programs.git.lfs.enable = true;

  programs.tmux.enable = true;
  programs.tmux.extraConfig = ''
    setw -g mouse on

    set -g update-environment "DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_CONNECTION WINDOWID XAUTHORITY"
  '';

  programs.bash.package = pkgs.bashInteractive;

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
