{ lib, stdenvNoCC, fetchurl }:
let
  releases = {
    x86_64-darwin = { platform = "macos-amd64"; sha256 = "cad39576a480d6bb02ea142fef1726647914b0d2da51ccc9b30b660a2b1babf0"; };
    aarch64-darwin = { platform = "macos-arm64"; sha256 = "eaf6c0c143e56dd9fa97bfb6df25ea9c1ebce40245f056a0768cf1a6c15d3064"; };
    x86_64-linux = { platform = "linux-amd64"; sha256 = "5669ddc46b99e942cc96078f4a4e36d5e62103348f4c05179ede27802fdd87a9"; };
    aarch64-linux = { platform = "linux-arm64"; sha256 = "ac2c028697199479acb321db1e3d68caee9f2ba492ed73caa3cd13f3829bf913"; };
  };
  release = releases.${stdenvNoCC.hostPlatform.system};
in stdenvNoCC.mkDerivation rec {
  pname = "d2-tala";
  version = "0.9.0";
  src = fetchurl {
    url = "https://github.com/d2lang/d2/releases/download/v${version}/d2-v${version}-${release.platform}.tar.gz";
    inherit (release) sha256;
  };
  dontBuild = true;
  dontFixup = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 bin/d2 $out/bin/d2
    runHook postInstall
  '';
  meta = {
    description = "Pinned D2 with bundled open-source TALA for the Topicmap experiment";
    homepage = "https://github.com/d2lang/d2";
    license = lib.licenses.mpl20;
    platforms = builtins.attrNames releases;
    mainProgram = "d2";
  };
}
