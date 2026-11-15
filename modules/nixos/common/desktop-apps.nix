{ inputs, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ghostty
    nautilus
    gnome-disk-utility

    # wayland clipboard fix
    wl-clipboard

    # Spelled out because the enclosing `with pkgs;` shadows the `system`
    # specialArg with pkgs.system, which is a deprecated alias.
    inputs.zen-browser.packages.${stdenv.hostPlatform.system}.beta
  ];

  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs._1password-gui.polkitPolicyOwners = [ "willothy" ];

  security.polkit.enable = true;

  services.flatpak.enable = true;

  programs.firefox.enable = true;
  programs.chromium.enable = true;

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
  ];
}
