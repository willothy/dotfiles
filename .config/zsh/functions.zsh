function fancy-ctrl-z () {
    if [[ $BUFFER = "" ]]; then
        fg
        zle accept-line
    else
        title "zsh"
        zle push-input -w
        zle clear-screen -w
        zle reset-prompt -w
    fi
}
zle -N fancy-ctrl-z

function pick_and_edit() {
    local file
    local dir
    if [ "$1" = "" ]; then
        dir="$PWD"
    else
        dir="$1"
    fi

    file="$(fd -t file --base-directory "$dir" | fzf)"
    if [ -z "$file" ]; then
        return 0
    fi
    nvim "$file"
}
zle -N pick_and_edit

TCLED=0

function tcled() {
    if test "$TCLED" -eq "1"; then
        TCLED=0
    else
        TCLED=1
    fi;
    echo "$TCLED" | sudo tee '/sys/class/leds/input28::capslock/brightness'
}
zle -N tcled

function psf() {
    ps -aux | rg -e "$1"
}

function brightness() {
    sudo brightnessctl -d intel_backlight set "$1%"
}

function fzd() {
    local dir
    local base
    local depth
    base="$1"
    depth="$2"
    if [ -z "$depth" ]; then
        depth=1
    fi
    if [ -z "$base" ]; then
        base="$PWD"
    fi
    dir="$(fd --type d --exclude .git --base-directory "$base" --maxdepth "$depth" --min-depth "$depth" | fzf)"
    if [ -z "$dir" ]; then
        return 0
    fi
    cd "$base/$dir" || return
}

function dots() {
    fzd "$HOME/.config" 1
}

function proj() {
    fzd "$HOME/projects" 2
}

function battery() {
    upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep -E 'state|time to|percentage'
}
