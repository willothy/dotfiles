self: super: {
  spider_cli = super.rustPlatform.buildRustPackage rec {
    pname = "spider_cli";
    version = "1.95.9";

    src = super.fetchCrate {
      pname = "spider_cli";
      version = "1.95.9";
      hash = "sha256-8RgnPm/vo+31r71X4D1yKo2FXACtuyap4S4bn51fs+U=";
    };

    cargoHash = super.lib.fakeHash;
    cargoLock.lockFile = src + /Cargo.lock;

    buildInputs = with super; [
      openssl
    ];
    nativeBuildInputs = with super; [
      pkg-config
    ];

    meta = {
      description = "A CLI for spider-rs";
      homepage = "https://github.com/spider-rs/spider";
      license = super.lib.licenses.mit;
      maintainers = [ ];
    };
  };
}
