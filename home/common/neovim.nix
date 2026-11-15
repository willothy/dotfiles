{ config, inputs, pkgs, lib, globalUserInfo, ... }:
let
  nvimConfigDir = "${config.xdg.configHome}/nvim";
in
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

  # nvim-config's init.lua reads this into vim.g.sqlite_clib_path, so nothing
  # nix-specific has to live inside the config repo.
  home.sessionVariables.NVIM_SQLITE_CLIB_PATH =
    "${pkgs.sqlite.out}/lib/libsqlite3${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}";

  # ~/.config/nvim is a live git clone of nvim-config, edited and reloaded
  # without a rebuild. Clone it on machines that don't have it yet; an
  # existing checkout is never touched. Over https, since activation has no
  # ssh agent; pushes still go over ssh.
  home.activation.cloneNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "${nvimConfigDir}/.git" ] && [ -z "$(ls -A "${nvimConfigDir}" 2>/dev/null)" ]; then
      if run ${pkgs.git}/bin/git clone https://github.com/willothy/nvim-config "${nvimConfigDir}"; then
        run ${pkgs.git}/bin/git -C "${nvimConfigDir}" remote set-url --push origin git@github.com:willothy/nvim-config
      else
        echo "warning: couldn't clone nvim-config into ${nvimConfigDir}; it'll be retried on the next activation" >&2
      fi
    fi
  '';
}
