{ inputs, config, pkgs, lib, globalUserInfo, ... }:
{
  imports = [ ../common ];

  home.username = globalUserInfo.userName;
  home.homeDirectory = globalUserInfo.homeDir;

  home.packages =
    with pkgs;
    let
      gdk = google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
        gke-gcloud-auth-plugin
      ]);
    in
    [
      gdk
    ];

  programs.git.lfs.enable = true;

  programs.tmux.enable = true;
  programs.tmux.extraConfig = ''
    setw -g mouse on

    set -g update-environment "DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_CONNECTION WINDOWID XAUTHORITY"
  '';

  programs.bash.package = pkgs.bashInteractive;

  home.file.".config/ghostty/config".source = ../../configs/ghostty/config;

  programs.gh.gitCredentialHelper.enable = false;
}
