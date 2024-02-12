#!/bin/bash

# dependency checks and boring stuff goes here
source "$ZDOTDIR/init.zsh"

# env variables
source "$ZDOTDIR/env.zsh"

# zsh settings
source "$ZDOTDIR/settings.zsh"

# filetype aliases
source "$ZDOTDIR/filetype.zsh"

# modified dircycle plugin
source "$ZDOTDIR/dircycle.zsh"

# misc prompt stuff
source "$ZDOTDIR/prompt_utils.zsh"

# utility functions and stuff
source "$ZDOTDIR/functions.zsh"

# custom autosuggestions sources (neosuggest and atuin)
source "$ZDOTDIR/autosuggestions.zsh"

# compinit
source "$ZDOTDIR/completion.zsh"

# all aliases go here (for now)
source "$ZDOTDIR/aliases.zsh"

# git-related functions
source "$ZDOTDIR/git_utils.zsh"

# zvm initialization functions
# keymaps are sourced here as they need to load
# lazily for ZVM to not overwrite them
source "$ZDOTDIR/zvm.zsh"

# load antidote and initialize plugins
source "$ZDOTDIR/antidote/antidote.zsh"
antidote load

# map caps to escape for vim purposes
setxkbmap -option caps:escape

# Neosuggest (my project)
eval "$(neosuggest init)"

# Zoxide
eval "$(zoxide init zsh)"

# Starship
eval "$(starship init zsh)"

source "$ZDOTDIR/startup.zsh"
