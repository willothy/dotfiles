export PATH="${HOME}/.local/bin:${PATH}"
export PATH="/usr/local/bin:${PATH}"
export PATH="/usr/bin:${PATH}"
export PATH="${HOME}/.cargo/bin:${PATH}"
export PATH="${HOME}/opt/cross/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"
export PATH="${HOME}/.luarocks/bin:${PATH}"
export PATH="${HOME}/vendor/zig:${PATH}"

setopt PROMPT_SUBST

# autoload -U select-word-style
# select-word-style normal


# Bindings
bindkey -s '^o' 'nvim $(fzf)^M'


bindkey '^I' forward-word #autosuggest-accept
bindkey '^ ' autosuggest-accept

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
zstyle :compinstall filename '/home/willothy/.zshrc'

autoload -Uz compinit

compinit
_comp_options+=(globdots)

# End of lines added by compinstall

test -z "$PROFILEREAD" && . /etc/profile || true

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    rust
    gh
    npm
    ripgrep
)

export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh


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

# alias proj='cd $(pickfile $(pickfile ~/projects --prompt Language) --prompt Project)'

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

# Dotfiles
alias config="/usr/bin/git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME"

# Git
function git() {
    if [ "$HOME" = "$PWD" ]; then
        config "$@"
    else
        /usr/bin/git "$@"
    fi
}

alias gs='git status'
alias gsp='git status --porcelain'
alias ga='git add'
alias glog='git log'
alias commit='git commit'
alias push='git push'
alias pull='git pull'

# Python
alias python3="python"
alias py="python"

# RIP
#alias rm="rip"

# Cloak
alias otp="cloak view" # otp github -> cloak view github
