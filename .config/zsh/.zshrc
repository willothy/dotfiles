# shellcheck disable=SC2034
# Install rustup if it isn't installed already
if ! [[ -s "${HOME}/.rustup" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- --no-modify-path -y
fi

export PATH="${HOME}/.local/bin:${PATH}"
export PATH="/usr/local/bin:${PATH}"
export PATH="/usr/bin:${PATH}"
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

export VISUAL="nvim -b"
export EDITOR="nvim"
export BROWSER="brave"

source "$ZDOTDIR/filetype.zsh"

# plugin settings

# Custom dircycle (modified from michaelxmcbride/zsh-dircycle) for compat with vi-mode
_dircycle_update_cycled() {
    setopt localoptions nopushdminus
    if [ $ZVM_HACKY_INIT_DONE -eq 0 ]; then
        zvm_select_vi_mode n
        zvm_select_vi_mode i
        ZVM_HACKY_INIT_DONE=1
    fi

    if [[ ${#dirstack} -eq 0 ]]; then
        zle reset-prompt
        return
    fi

    while ! builtin pushd -q "$1" &>/dev/null; do
        # A missing directory was found; pop it out of the directory stack.
        builtin popd -q "$1" || return

        # Stop trying if there are no more directories in the directory stack.
        [[ ${#dirstack} -eq 0 ]] && break
    done
    zle reset-prompt
}

_dircycle_insert_cycled_left() {
    _dircycle_update_cycled +1
}

_dircycle_insert_cycled_right() {
    _dircycle_update_cycled -0
}

ZVM_HACKY_INIT_DONE=0

function zvm_config() {
    ZVM_VI_SURROUND_BINDKEY=classic
}

function zvm_after_init() {
    zle -N _dircycle_insert_cycled_left
    zle -N _dircycle_insert_cycled_right

    zvm_define_widget _dircycle_insert_cycled_left
    zvm_define_widget _dircycle_insert_cycled_right

    bindkey '^[[1;6D' _dircycle_insert_cycled_left
    bindkey '^[[1;6C' _dircycle_insert_cycled_right

    zvm_bindkey vicmd '^[[1;6D' _dircycle_insert_cycled_left
    zvm_bindkey vicmd '^[[1;6C' _dircycle_insert_cycled_right

    zvm_bindkey visual '^[[1;6D' _dircycle_insert_cycled_left
    zvm_bindkey visual '^[[1;6C' _dircycle_insert_cycled_right

    zvm_bindkey vicmd '^[[A' up-line-or-beginning-search
    zvm_bindkey vicmd '^[[B' down-line-or-beginning-search
    zvm_bindkey visual '^[[A' up-line-or-beginning-search
    zvm_bindkey visual '^[[B' down-line-or-beginning-search
}

fancy-ctrl-z () {
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
bindkey '^Z' fancy-ctrl-z

source "${ZDOTDIR:-~}/antidote/antidote.zsh"

antidote load

# autoload -U select-word-style
# select-word-style normal

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
zle -N pick_and_edit # define widget

# Bindings
# bindkey -v

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

bindkey '\e[A' up-line-or-beginning-search
bindkey '\e[B' down-line-or-beginning-search

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

_zsh_autosuggest_strategy_atuin-cwd() {
    suggestion="$(RUST_LOG=error atuin search --limit 1 --filter-mode directory --cmd-only --search-mode prefix -- "$BUFFER")"
}

_zsh_autosuggest_strategy_atuin-session() {
    suggestion="$(RUST_LOG=error atuin search --limit 1 --filter-mode session --cmd-only --search-mode prefix -- "$BUFFER")"
}

_zsh_autosuggest_strategy_atuin-global() {
    suggestion="$(RUST_LOG=error atuin search --limit 1 --filter-mode global --cmd-only --search-mode prefix -- "$BUFFER")"
}

export ZSH_AUTOSUGGEST_STRATEGY=(
    atuin-cwd      # pwd history
    neosuggest     # pwd files/dirs and zoxide
    atuin-session  # session history
    atuin-global   # global history
    completion     # base zsh completion
)

zstyle :compinstall filename '/home/willothy/.config/zsh/.zshrc'

autoload -Uz compinit

compinit
_comp_options+=(globdots)

test -z "$PROFILEREAD" && . /etc/profile

zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"
zstyle '*' single-ignored show

zstyle ':completion:*:*:*:users' ignored-patterns \
    adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
    clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
    gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
    ldap lp mail mailman mailnull man messagebus  mldonkey mysql nagios \
    named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
    operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
    rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
    usbmux uucp vcsa wwwrun xfs '_*'

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# Td todos
td init

# Neosuggest
eval "$(neosuggest init)"

# Zoxide
eval "$(zoxide init zsh)"

# Atuin
eval "$(atuin init zsh --disable-up-arrow)"

# Sesh wezterm integration using Usar Vars

export LS_COLORS=$LS_COLORS:'di=1;34:'

export TCLED=0

function tcled() {
    if test "$TCLED" -eq "1"; then
        TCLED=0
    else
        TCLED=1
    fi;
    echo "$TCLED" | sudo tee '/sys/class/leds/input28::capslock/brightness'
}
PROMPT="$(printf "\033]1337;SetUserVar=%s=%s\007" "sesh_name" "$(echo -n "$SESH_NAME" | base64)")$PROMPT"

# Starship
eval "$(starship init zsh)"

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

# Ls / Exa
alias ls='exa --icons'
alias la='exa -a --icons'
alias ll='exa -l --icons'
alias lla='exa -la --icons'

# cd
alias ..='cd ..'
alias .1='cd ..'
alias .2='cd ../..'
alias .3='cd ../../..'
alias :q='exit'

# Dotfiles / projects
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

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
    if [ "$dir" != "" ] && [[ "$dir" =~ $HOME/.dotfiles[/]?$ ]] && [ "$1" != "clone" ]; then
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

#list whats inside packed file
alias -s zip="unzip -l"
alias -s rar="unrar l"
alias -s tar="tar tf"
alias -s tar.gz="echo "

zsh-startify
