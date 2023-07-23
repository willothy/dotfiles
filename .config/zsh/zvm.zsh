function zvm_config() {
    # shellcheck disable=SC2034
    ZVM_VI_SURROUND_BINDKEY=classic
}

function zvm_after_init() {
    source "$ZDOTDIR/keybinds.zsh"
}

function zvm_after_select_vi_mode() {
    starship_vi_mode
}
