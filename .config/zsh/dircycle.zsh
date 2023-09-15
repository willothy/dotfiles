ZVM_HACKY_INIT_DONE=0

# Custom dircycle (modified from michaelxmcbride/zsh-dircycle) for compat with vi-mode
_dircycle_update_cycled() {
    setopt localoptions nopushdminus

    # when starting up, this won't work until the first time we've
    # exited insert mode. this does that quickly to get it out of the way.
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

zle -N _dircycle_insert_cycled_left
zle -N _dircycle_insert_cycled_right

function dupd() {
    local dir
    dir=$dirstack[1]
    if [[ -z $dir ]]; then
        dir=$PWD
    fi
    builtin pushd "$dir"
}
