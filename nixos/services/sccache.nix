{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    sccache
  ];

  environment.variables = {
    RUSTC_WRAPPER = "sccache";
    SCCACHE_CACHE_SIZE = "64G";
  };

  systemd.user.services.sccache = {
    enable = true;
    description = "sccache server";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.sccache}/bin/sccache --start-server";
      ExecStop = "${pkgs.sccache}/bin/sccache --stop-server";
      Type = "forking";
    };
  };
}
