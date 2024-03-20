#!/bin/bash

export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.bun/bin:$PATH"
export PATH="${HOME}/.cargo/bin:${PATH}"
export PATH="/usr/local/bin:${PATH}"
export PATH="/usr/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"
export PATH="${HOME}/.luarocks/bin:${PATH}"
export PATH="${HOME}/vendor/zig:${PATH}"

# Turso
export PATH="/home/willothy/.turso:$PATH"

# export WORDCHARS='-_.'
# export LS_COLORS=$LS_COLORS:'di=1;34:'

# fix for Nix
export LC_ALL="C"
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
