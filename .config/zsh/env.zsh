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

# export ANDROID_HOME="${HOME}/android-sdk"
# export PATH="$ANDROID_HOME/tools/bin/:$PATH"
# export JAVA_HOME="/usr/lib/jvm/java-21-openjdk/"

# export WORDCHARS='-_.'
# export LS_COLORS=$LS_COLORS:'di=1;34:'

# fix for Nix
export LC_ALL="C"
if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi
