# fixes issues with docutils build
final: prev: {
  python312 = prev.python312.overrideAttrs (old: {
    # Replace only the "doc" output with a trivial build.
    # Other outputs (out, dev, lib, etc.) remain untouched.
    outputs = (old.outputs or [ "out" ]) ++ [ "doc" ];

    postInstall = (old.postInstall or "") + ''
            if [ -n "''${doc-}" ]; then
              mkdir -p "$doc"
              cat > "$doc/README.txt" <<'EOF'
      Python 3.12 docs output disabled in this system build.
      Reason: upstream Sphinx/docutils regression breaks CPython docs build.
      EOF
            fi
    '';

    # Ensure nothing tries to build real docs in the build phase.
    # (Most of the time the doc output is built by a separate derivation,
    # but this makes the doc output exist and be non-empty.)
  });
}
