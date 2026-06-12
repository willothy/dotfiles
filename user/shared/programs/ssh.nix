{ config, pkgs, globalUserInfo, ... }: {
  programs.ssh =
    let
      darwin = pkgs.system == "aarch64-darwin";
      socket =
        if darwin then
          "${globalUserInfo.homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        else
          "${globalUserInfo.homeDir}/.1password/agent.sock"
      ;
      orbstack =
        if darwin then
          "Include ${globalUserInfo.homeDir}/.orbstack/ssh/config"
        else
          ""
      ;
    in
    {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          host = "*";
          extraOptions.IdentityAgent = ''"${socket}"'';
          forwardAgent = true;
        };
        nostromo = {
          host = "nostromo";
          extraOptions.IdentityAgent = ''"${socket}"'';
          forwardAgent = true;
        };
      };
      extraConfig = ''
        ${orbstack}

        Host kitchen
          HostName 192.168.50.156
          SetEnv TERM="xterm-256color"

        Host nostromo
          HostName nostromo
          SetEnv TERM="xterm-256color"

        Host dev-vm
          HostName 192.168.10.135
      '';
    };
}
