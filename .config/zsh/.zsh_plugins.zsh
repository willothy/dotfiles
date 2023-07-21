fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions/zsh-completions.plugin.zsh
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
if ! (( $+functions[zsh-defer] )); then
  fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search )
zsh-defer source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
