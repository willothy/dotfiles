#!/usr/bin/env bash

# Neovim
alias nv="TERM=wezterm nvim"
alias v="TERM=wezterm nvim"
alias vim="TERM=wezterm nvim"
alias vi="TERM=wezterm nvim"
alias nvim="TERM=wezterm nvim"
alias nvcfg="nvim ~/.config/nvim/"

# Walk
alias w="walk"

# Safe rm
# alias rm='rip'

# Zoxide
alias cd='z'

# Cat / Bat
alias cat='bat'

# Sesh
alias detach='sesh detach'
alias attach='sesh attach'

# Ls / Exa
alias ls='eza --icons'
alias la='eza -a --icons'
alias ll='eza -l --icons'
alias lla='eza -la --icons'

# cd
alias ..='cd ..'
alias .1='cd ..'
alias .2='cd ../..'
alias .3='cd ../../..'
alias :q='exit'

# Dotfiles / projects
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Git
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
alias grb='git rebase'
alias gspop='git stash pop'
alias gspush='git stash push'
alias gsdrop='git stash drop'

# Python
alias python3="python"
alias py="python"

# list whats inside packed file
alias -s zip="unzip -l"
alias -s rar="unrar l"
alias -s tar="tar tf"
alias -s tar.gz="echo "


# sesh
# alias exit='sesh detach || exit' # do I want this?
