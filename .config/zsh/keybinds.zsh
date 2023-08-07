bindkey '^[[1;6D' _dircycle_insert_cycled_left
bindkey '^[[1;6C' _dircycle_insert_cycled_right

# bindkey -rM visual "^r"
bindkey -r "^r"
bindkey -rM vicmd "^r"
bindkey -r "^j"
bindkey -rM vicmd "^j"

# Atuin
eval "$(atuin init zsh --disable-up-arrow)"

bindkey "^r" _atuin_search_widget

bindkey '^Z' fancy-ctrl-z

# <C-o> fzf current dir, open result in nvim
bindkey '^o' pick_and_edit

# <C-Tab>    : accept word
bindkey '^I' forward-word
# <S-Tab>   : completion menu
bindkey '^[[Z' menu-complete
# <C-Space>  : accept all
bindkey '^ ' autosuggest-accept

# prefix search with up/down arrow
autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# <C-x><C-e>    : edit command line in $VISUAL
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# <Home>        : go to beginning of line
bindkey '^[[H' beginning-of-line
# <End>         : go to end of line
bindkey '^[[F' end-of-line

# <Del>         : delete char forwards
bindkey "^[[3~" delete-char
# <BS>          : delete char backwards
bindkey '^?' backward-delete-char

# <C-Right>     : go to end of word
bindkey '^[[1;5C' forward-word
# <C-Left>      : go to beginning of word
bindkey '^[[1;5D' backward-word

# <C-BS>        : delete word backwards
bindkey '^H' backward-kill-word
# <C-Del>       : delete word forwards
bindkey '^[[3;5~' kill-word

# <C-W>         : delete region backwards
bindkey '^W' kill-region

bindkey "^[m" copy-prev-shell-word
