. "$HOME/.cargo/env"
export PATH="${HOME}/.local/bin:${PATH}"
export PATH="/usr/local/bin:${PATH}"
export PATH="/usr/bin:${PATH}"
export PATH="${HOME}/opt/cross/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"
export PATH="${HOME}/.luarocks/bin:${PATH}"
export PATH="${HOME}/vendor/zig:${PATH}"

export HISTFILE="${ZDOTDIR:-~}/.zsh_history"
export HISTFILESIZE=100000
export HISTSIZE=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY
setopt HIST_VERIFY

setopt PROMPT_SUBST

# autoload -U select-word-style
# select-word-style normal

function pickfile() {
    local file
    local dir
    dir="$1"
    if [ -z "$dir" ]; then
        dir="$PWD"
    fi
    file="$(cd $dir; fzf)"
    if [ -z "$file" ]; then
        return 0
    fi
    nvim "$file"
}

# Bindings
bindkey -s '^o' pickfile         # <Ctrl-o>      : fzf current dir

bindkey '^I' forward-word        # <Ctrl-Tab>    : accept word
bindkey '^ ' autosuggest-accept  # <Ctrl-Space>  : accept all
bindkey -s '\el' 'ls\n'          # <Esc-l>       : run command: ls


_zsh_autosuggest_strategy_atuin-cwd() {
    suggestion=$(RUST_LOG=error atuin search --limit 1 --filter-mode directory --cmd-only --search-mode prefix -- $BUFFER)
}

_zsh_autosuggest_strategy_atuin-session() {
    suggestion=$(RUST_LOG=error atuin search --limit 1 --filter-mode session --cmd-only --search-mode prefix -- $BUFFER)
}

_zsh_autosuggest_strategy_atuin-global() {
    suggestion=$(RUST_LOG=error atuin search --limit 1 --filter-mode global --cmd-only --search-mode prefix -- $BUFFER)
}

export ZSH_AUTOSUGGEST_STRATEGY=(
    atuin-cwd      # pwd history
    neosuggest     # pwd files/dirs and zoxide
    atuin-session  # session history
    atuin-global   # global history
    completion     # base zsh completion
)

bindkey -e
zstyle :compinstall filename '/home/willothy/.config/zsh/.zshrc'

autoload -Uz compinit

compinit
_comp_options+=(globdots)

test -z "$PROFILEREAD" && . /etc/profile || true

source ${ZDOTDIR:-~}/antidote/antidote.zsh

antidote load

# Td todos
td init

# Neosuggest
eval "$(neosuggest init)"

# Zoxide
eval "$(zoxide init zsh)"

# Atuin
eval "$(atuin init zsh --disable-up-arrow)"

# Sesh wezterm integration using Usar Vars

export VISUAL="nvim -b"
export EDITOR=nvim

export LS_COLORS=$LS_COLORS:'di=1;34:'

export TCLED=0

function tcled() {
    if test $TCLED -eq 1; then
        TCLED=0
    else
        TCLED=1
    fi;
    echo "$TCLED" | sudo tee '/sys/class/leds/input28::capslock/brightness'
}
PROMPT="$(printf "\033]1337;SetUserVar=%s=%s\007" "sesh_name" `echo -n "$SESH_NAME" | base64`)$PROMPT"

function set_win_title(){
    echo -ne "\033]0; zsh \007"
}

# Starship
eval "$(starship init zsh)"
precmd_functions+=(set_win_title)

# handy aliases

function psf() {
	ps -aux | rg -e "$1"
}

function brightness() {
    sudo brightnessctl -d intel_backlight set "$1%"
}


export WORDCHARS='-_.'

setxkbmap -option caps:escape
# xmodmap
# xmodmap ~/.xmodmap

# Neovim
alias nv="nvim"
alias v="nvim"
alias vim="nvim"
alias vi="nvim"
alias nvcfg="nvim ~/.config/nvim/"

# Zoxide
alias cd='z'

# Cat / Bat
alias cat='bat'

# Sesh
alias detach='sesh detach'
alias attach='sesh attach'
alias exit='detach || exit'
alias exit!='exec exit'

# Ls / Exa
alias ls='exa --icons'
alias la='exa -a --icons'
alias ll='exa -l --icons'
alias lla='exa -la --icons'

# Dotfiles / projects
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

function proj() {
    local dir
    dir=$(fd --type d --exclude .git --base-directory ~/projects --maxdepth 2 --min-depth 2 | fzf)
    echo "$dir"
    if [ -z "$dir" ]; then
        return 0
    fi
    cd "$HOME/projects/$dir"
}

# Git

function is_in_repo() {
    # return true if command returned success
    if /usr/bin/git rev-parse --git-dir > /dev/null 2>&1; then
        return 0
    elif config rev-parse --git-dir > /dev/null 2>&1; then
        return 1
    else
        return 2
    fi
}

# get current git dir, if any, including dotfiles dir
function git_dir() {
    local is_repo
    is_in_repo
    is_repo=$?
    local dir

    if [ $is_repo = 0 ]; then
        /usr/bin/git rev-parse --git-dir
    elif [ $is_repo = 1 ]; then
        config rev-parse --git-dir
    fi
}

# use dotfiles dir if not cloning repo and in non-repo subdir of dotfiles
function git() {
    local dir
    dir=$(git_dir)
    if [ "$dir" != "" ] && [[ "$dir" =~ "$HOME/.dotfiles[/]?$" ]] && [ "$1" != "clone" ]; then
        config "$@"
    else
        /usr/bin/git "$@"
    fi
}

alias gs='git status'
alias gsp='git status --porcelain'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit --verbose'
alias gau='git add --update'
alias glog='git log'
alias commit='git commit --verbose'
alias push='git push'
alias pull='git pull'

# Python
alias python3="python"
alias py="python"

# RIP
#alias rm="rip"

# Cloak
alias otp="cloak view" # otp github -> cloak view github
