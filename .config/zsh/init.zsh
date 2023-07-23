# shellcheck disable=SC2034
# Install rustup if it isn't installed already
if ! [[ -s "${HOME}/.rustup" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- --no-modify-path -y
fi

test -z "$PROFILEREAD" && . /etc/profile
