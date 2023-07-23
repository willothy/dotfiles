# escape sequences
bold_purple="\e[1;35m"
bold_red="\e[1;31m"
bold_green="\e[1;32m"
bold_yellow="\e[1;33m"
bold_cyan="\e[1;36m"
bold_blue="\e[1;34m"
reset_color="\e[0m"

normal=$bold_blue
insert=$bold_green
visual=$bold_yellow
visual_line=$bold_yellow
replace=$bold_red

function starship_vi_mode() {
    case $ZVM_MODE in
        "$ZVM_MODE_NORMAL")
            ZVM_MODE_PROMPT="$normal->$reset"
            zle reset-prompt
            ;;
        "$ZVM_MODE_INSERT")
            ZVM_MODE_PROMPT="$insert->$reset"
            zle reset-prompt
            ;;
        "$ZVM_MODE_VISUAL")
            ZVM_MODE_PROMPT="$visual->$reset"
            zle reset-prompt
            ;;
        "$ZVM_MODE_VISUAL_LINE")
            ZVM_MODE_PROMPT="$visual_line->$reset"
            zle reset-prompt
            ;;
        "$ZVM_MODE_REPLACE")
            ZVM_MODE_PROMPT="$replace->$reset"
            zle reset-prompt
            ;;
    esac
}
export ZVM_MODE_PROMPT="$insert->$reset"

__wezterm_set_user_var() {
    if hash base64 2>/dev/null ; then
        if [[ -z "${TMUX}" ]] ; then
            printf "\033]1337;SetUserVar=%s=%s\007" "$1" `echo -n "$2" | base64`
        else
            # <https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it>
            # Note that you ALSO need to add "set -g allow-passthrough on" to your tmux.conf
            printf "\033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\" "$1" `echo -n "$2" | base64`
        fi
    fi
}

# sets wezterm user var to make the current session known to wezterm
function __sesh_name() {
    __wezterm_set_user_var "sesh_name" "$SESH_NAME"
}
precmd_functions+=(__sesh_name)
