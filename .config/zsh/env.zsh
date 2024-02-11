#!/bin/sh

export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.bun/bin:$PATH"
export PATH="${HOME}/.cargo/bin:${PATH}"
export PATH="/usr/local/bin:${PATH}"
export PATH="/usr/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"
export PATH="${HOME}/.luarocks/bin:${PATH}"
export PATH="${HOME}/vendor/zig:${PATH}"

export WORDCHARS='-_.'
export LS_COLORS=$LS_COLORS:'di=1;34:'

#export TERM="wezterm"
export VISUAL="nvim -b"
export EDITOR="nvim"
export BROWSER="brave"
export SUDO_ASKPASS="/usr/bin/xaskpass"
export SSH_ASKPASS="/usr/bin/xaskpass"
