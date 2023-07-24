export PATH="${HOME}/.cargo/bin:${PATH}"
export PATH="${HOME}/.local/bin:${PATH}"
export PATH="/usr/local/bin:${PATH}"
export PATH="/usr/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"
export PATH="${HOME}/.luarocks/bin:${PATH}"
export PATH="${HOME}/vendor/zig:${PATH}"
[ -f "/home/willothy/.ghcup/env" ] && source "/home/willothy/.ghcup/env"

export WORDCHARS='-_.'
export LS_COLORS=$LS_COLORS:'di=1;34:'

export SRC_ENDPOINT="https://sourcegraph.com"
export SRC_ACCESS_TOKEN="$(lpass show --field=Key Sourcegraph)"

export VISUAL="nvim -b"
export EDITOR="nvim"
export BROWSER="brave"
