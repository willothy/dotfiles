self: super:
let
  repo = "https://github.com/bufbuild/buf";
  version = "1.32.2";

  release = builtins.getAttr super.stdenv.system {
    "x86_64-darwin" = {
      platform = "Darwin-x86_64";
      checksum = "sha256-B9XGX4x2uyW2yxo82GqnbJB8/PJ4dfJbDus0svaxwxI=";
    };
    "x86_64-linux" = {
      platform = "Linux-x86_64";
      checksum = "sha256-B9XGX4x2uyW2yxo82GqnbJB8/PJ4dfJbDus0svaxwxI=";
    };
    "aarch64-darwin" = {
      platform = "Darwin-arm64";
      checksum = "sha256-/VzgbnvUUdQbhcdvG9jSDEszBgOqHQr7d8s81fKJisk=";
    };
    "aarch64-linux" = {
      platform = "linux-aarch64";
      checksum = "sha256-/VzgbnvUUdQbhcdvG9jSDEszBgOqHQr7d8s81fKJisk=";
    };
  };
in
{
  buf = super.stdenv.mkDerivation rec {
    pname = "buf";
    inherit version;

    src = super.fetchurl {
      url = "${repo}/releases/download/v${version}/buf-${release.platform}";
      sha256 = release.checksum;
    };

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/buf
      chmod +x $out/bin/buf
    '';

    meta = with super.lib; {
      description = "A new way of working with Protocol Buffers.";
      homepage = "https://buf.build";
      license = licenses.asl20;
      platforms = platforms.linux ++ platforms.darwin;
    };
  };
}
