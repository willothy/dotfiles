{ config, pkgs, globalUserInfo, ... }:
let
  onepassword = import ./onepassword.nix { inherit pkgs globalUserInfo; };

  # Local sessions sign through the 1Password app; SSH sessions sign with
  # ssh-keygen through the forwarded agent, so signing works over SSH even
  # when this machine's 1Password is locked.
  sshSign = pkgs.writeShellScript "git-ssh-sign" ''
    if ${onepassword.useLocalAgent}; then
      exec "${onepassword.sshSign}" "$@"
    fi
    exec ${pkgs.openssh}/bin/ssh-keygen "$@"
  '';
in
{
  programs.git = {
    enable = true;
    signing = {
      key = globalUserInfo.sshPublicKey;
      signByDefault = true;
    };
    settings = {
      user = {
        name = globalUserInfo.fullName;
        inherit (globalUserInfo) email;
      };
      init = {
        defaultBranch = "main";
      };
      color.pager = "yes";
      "gpg \"ssh\"" = {
        program = "${sshSign}";
        allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
      };
      gpg.format = "ssh";
      pull = {
        rebase = true;
      };
    };
  };

  xdg.configFile."git/allowed_signers".text = ''
    ${globalUserInfo.email} ${globalUserInfo.sshPublicKey}
  '';

  programs.gh = {
    enable = true;
    extensions = [ ];
    settings = {
      git_protocol = "ssh";
      aliases = { };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
    };
  };
}
