{ pkgs, ... }:
{
  environment.systemPackages = [
    # I will go insane without this
    (pkgs.vim-full.customize {
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ vim-nix vim-lastplace ];
        opt = [ ];
      };
      vimrcConfig.customRC = ''
        filetype plugin indent on
        syntax on

        set shiftwidth=2
        set tabstop=2
        set expandtab

        set showtabline=3
        set scrolloff=10

        set number relativenumber

        set nowrap hlsearch incsearch showmode

        set clipboard=unnamedplus
      '';
    })
  ];
}
