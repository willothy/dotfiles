{ inputs, ... }:
{
  imports = [ inputs.rex.homeManagerModules.default ];

  # rex CLI, its xterm-rex terminfo, and the ssh guard that keeps ssh from
  # passing that terminal type to hosts that don't know it. The server itself
  # runs as a system service on the Linux hosts (modules/nixos/common/rex.nix);
  # on the Mac the Rex app runs it.
  programs.rex.enable = true;
}
