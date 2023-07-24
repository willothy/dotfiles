fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-mroth-SLASH-evalcache )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-mroth-SLASH-evalcache/evalcache.plugin.zsh
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ael-code-SLASH-zsh-colored-man-pages )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ael-code-SLASH-zsh-colored-man-pages/colored-man-pages.plugin.zsh
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-jeffreytse-SLASH-zsh-vi-mode )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-jeffreytse-SLASH-zsh-vi-mode/zsh-vi-mode.plugin.zsh
export PATH="/home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-bigH-SLASH-git-fuzzy/bin:$PATH"
export PATH="/home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-tj-SLASH-git-extras/bin:$PATH"
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-tj-SLASH-git-extras/etc )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-tj-SLASH-git-extras/etc/git-extras-completion.zsh
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions )
source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions/zsh-completions.plugin.zsh
if ! (( $+functions[zsh-defer] )); then
  fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-Freed-Wu-SLASH-zsh-command-not-found )
zsh-defer source /home/willothy/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-Freed-Wu-SLASH-zsh-command-not-found/command-not-found.plugin.zsh
