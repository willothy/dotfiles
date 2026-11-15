{ pkgs, ... }: {
  # programs.neovim = {
  #   package = pkgs.neovim;
  #   enable = true;
  # };

  home.packages = with pkgs; [ sqlite ];

  # FIXME: This isn't needed for nix-darwin, only on NixOS
  # lua/plugins/* gets autoloaded by Lazy, so I use this to
  # do required nix-specific setup.
  # home.file.".config/nvim/lua/plugins/nix.lua" =
  #   let
  #     platform_ext =
  #       if (builtins.match "darwin$" pkgs.system) == null then
  #         "dylib"
  #       else
  #         "so"
  #     ;
  #   in
  #   {
  #     text = ''
  #       -- set sqlite library path for sqlite.lua
  #       vim.g.sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3.${platform_ext}"
  #
  #       return {}
  #     '';
  #   };
}
