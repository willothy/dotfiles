
# depends on "config" alias, source before aliases.zsh
function __is_in_repo() {
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
function __git_dir() {
    local is_repo
    __is_in_repo
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
    dir=$(__git_dir)
    if [ "$dir" != "" ] && [[ "$dir" =~ $HOME/.dotfiles[/]?$ ]] && [ "$1" != "clone" ] && [ "$1" != "init" ]; then
        config "$@"
    else
        /usr/bin/git "$@"
    fi
}

function git_root() {
    git rev-parse --show-toplevel
}
