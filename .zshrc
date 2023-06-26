export PATH="${HOME}/.local/bin:${PATH}"
export PATH="/usr/local/bin:${PATH}"
export PATH="/usr/bin:${PATH}"
export PATH="${HOME}/.cargo/bin:${PATH}"
export PATH="${HOME}/opt/cross/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"
export PATH="${HOME}/.luarocks/bin:${PATH}"
export PATH="${HOME}/vendor/zig:${PATH}"

setopt PROMPT_SUBST

autoload -U select-word-style
select-word-style bash

# Bindings
bindkey -s '^o' 'nvim $(fzf)^M'

eval "$(neosuggest init)"

function set_win_title(){
    echo -ne "\033]0; zsh \007"
}

# Starship
eval "$(starship init zsh)"
precmd_functions+=(set_win_title)

# Zoxide
eval "$(zoxide init zsh)"

bindkey '^I' forward-word #autosuggest-accept
bindkey '^ ' autosuggest-accept

# Atuin
eval "$(atuin init zsh)"

_zsh_autosuggest_strategy_atuin() {
    suggestion=$(RUST_LOG=error atuin search --limit 1 --cwd="$PWD" --cmd-only --search-mode prefix -- $BUFFER)
}

export ZSH_AUTOSUGGEST_STRATEGY=(atuin neosuggest completion)

# Lines configured by zsh-newuser-install
export HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
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
	rust
	gh
	npm
	ripgrep
)

export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# xmodmap
# xmodmap ~/.Xmodmap


# Td todos
td init

# Sesh wezterm integration using Usar Vars

export VISUAL="nvim --cmd 'let g:flatten_wait=1'"
# export VISUAL=nvim
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

# handy aliases

function psf() {
	ps -aux | rg -e $1
}

function nvimdev() {
    nvim --cmd "let g:dev=\"$1\"" ${@:2}
}

function brightness() {
    sudo brightnessctl -d intel_backlight set $1%
}

# alias proj='cd $(pickfile $(pickfile ~/projects --prompt Language) --prompt Project)'

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

# Ls / Exa
alias ls='exa --icons'
alias la='exa -a --icons'
alias ll='exa -l --icons'
alias lla='exa -la --icons'

# Dotfiles
alias config="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

# Git
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
