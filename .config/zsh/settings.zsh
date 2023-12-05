export HISTFILE=${ZDOTDIR}/.zsh_history
export HISTFILESIZE=100000
export HISTSIZE=100000
export SAVEHIST=100000

setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY
setopt HIST_VERIFY

setopt PROMPT_SUBST
unset zle_bracketed_paste

. "${ZDOTDIR}/plugin_settings.zsh"
