final: prev: {
  sccache = prev.rustPlatform.buildRustPackage
    rec {
      pname = "sccache";
      version = "0.10.0";

      src = prev.fetchFromGitHub {
        owner = "mozilla";
        repo = "sccache";
        rev = "v${version}";
        sha256 = "sha256-VEDMeRFQKNPS3V6/DhMWxHR7YWsCzAXTzp0lO+COl08="; # You'll need to get the real hash
      };

      cargoHash = "sha256-1kfKBN4uRbU5LjbC0cLgMqoGnOSEAdC0S7EzXlfaDPo=";

      nativeBuildInputs = with prev; [
        pkg-config
      ];

      buildInputs = with prev; [
        openssl
      ] ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
        prev.darwin.apple_sdk.frameworks.Security
        prev.darwin.apple_sdk.frameworks.SystemConfiguration
      ];

      doCheck = false;

      meta = with prev.lib; {
        description = "Shared compilation cache";
        homepage = "https://github.com/mozilla/sccache";
        license = licenses.asl20;
        maintainers = [ ];
      };
    };
}
