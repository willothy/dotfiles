{ inputs, pkgs, lib, globalUserInfo, ... }:
{
  # `nvim -b`: flatten.nvim repurposes -b so that an nvim opened as $VISUAL
  # inside a nested nvim terminal hands the file to the outer nvim and blocks
  # until it's closed. Overrides defaultEditor's plain VISUAL=nvim.
  home.sessionVariables.VISUAL = lib.mkForce globalUserInfo.editorVisual;

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

  # lua/plugins/* gets autoloaded by Lazy, so I use this to
  # do required nix-specific setup.
  home.file.".config/nvim/plugin/nix.lua".text = ''
    -- set sqlite library path for sqlite.lua
    vim.g.sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}"

    return {}
  '';
}
