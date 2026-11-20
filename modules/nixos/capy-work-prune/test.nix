# Runs the fake-tree tests in test.sh against the prune command a host runs.
{
  pkgs,
  package,
}:
let
  test = pkgs.writeShellApplication {
    name = "capy-work-prune-test";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnugrep
      util-linux
    ];
    text = builtins.readFile ./test.sh;
  };
in
pkgs.runCommand "capy-work-prune-test" { } ''
  ${test}/bin/capy-work-prune-test ${package}/bin/capy-work-prune
  touch $out
''
