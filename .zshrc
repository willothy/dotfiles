export PATH="${HOME}/.local/bin:${PATH}"
export PATH="/usr/local/bin:${PATH}"
export PATH="/usr/bin:${PATH}"
export PATH="${HOME}/.cargo/bin:${PATH}"
export PATH="${HOME}/opt/cross/bin:${PATH}"
export PATH="${HOME}/go/bin:${PATH}"

# Bindings
bindkey -s '^o' 'nvim $(fzf)^M'

eval "$(neosuggest init)"

export ZSH_AUTOSUGGEST_STRATEGY=(neosuggest)

# Lines configured by zsh-newuser-install
export HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
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

# Starship
eval "$(starship init zsh)"

# Zoxide
eval "$(zoxide init zsh)"

bindkey '^I' neosuggest-accept
bindkey '^ ' autosuggest-fetch

# Td todos
td init

export VISUAL="nvim --cmd 'let g:flatten_wait=1'"
# export VISUAL=nvim
export EDITOR=nvim

export LS_COLORS=$LS_COLORS:'di=1;34:'

# handy aliases
alias ls='exa --icons'
alias la='exa -a --icons'
alias ll='exa -l --icons'
alias lla='exa -la --icons'

alias gs='git status'

alias py="python3.10"
alias python3="python3.10"
alias python="python3.10"

function nvimdev() {
    nvim --cmd "let g:dev=\"$1\"" ${@:2}
}

alias proj='cd $(pickfile $(pickfile ~/projects --prompt Language) --prompt Project)'

alias nv="nvim"
alias v="nvim"
alias vim="nvim"
alias vi="nvim"
alias nvcfg="nvim ~/.config/nvim/"

alias cd='z'
alias cat='bat'

alias config="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

