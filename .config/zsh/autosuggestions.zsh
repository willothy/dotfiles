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
    neosuggest     # pwd files/dirs and zoxide
    atuin-cwd      # pwd history
    atuin-session  # session history
    atuin-global   # global history
    completion     # base zsh completion
)
