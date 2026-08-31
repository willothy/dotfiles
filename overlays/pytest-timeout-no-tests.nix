# fix some bullshit with python build
final: prev: {
  python312Packages = prev.python312Packages.overrideScope (pyFinal: pyPrev: {
    pytest-timeout = pyPrev.pytest-timeout.overridePythonAttrs (old: {
      doCheck = false;
      # (optional) if nixpkgs uses pytestCheckHook on this package:
      pytestCheckPhase = "true";
    });
  });
}
