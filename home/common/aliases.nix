let
  shellAliases = {
    ll = "ls -l";
    la = "ls -a";
    ls = "eza -s type";
    lt = "eza --tree -s type";
    ".." = "cd ..";
    gs = "git status";
    gc = "git commit";
    ga = "git add";
    gaa = "git add --all";
    gau = "git add --update";
    v = "nvim";
    ":q" = "exit";
    pls = "sudo";
    #cd = "z";
  };
in
{
  programs.fish.shellAliases = shellAliases;
  programs.bash.shellAliases = shellAliases;
  programs.zsh.shellAliases = shellAliases;
}
