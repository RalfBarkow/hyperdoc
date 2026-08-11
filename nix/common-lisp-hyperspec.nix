{
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "common-lisp-hyperspec";
  version = "7.0";

  src = fetchurl {
    url = "https://ftp.lispworks.com/pub/software_tools/reference/HyperSpec-7-0.tar.gz";
    hash = "sha256-GsFmap3Gl9vYiBJiytQ3G80umEMQi2Q+Lqk0crqF18M=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    corpus="$out/share/common-lisp-hyperspec/HyperSpec"
    mkdir -p "$corpus"
    cp -R . "$corpus/"

    test -f "$corpus/Front/index.htm"
    test -f "$corpus/Body/m_defmet.htm"
    test -d "$corpus/Data"
    test -d "$corpus/Issues"

    # CLOG's static-plugin convention matches the URL prefix basename
    # against a sibling filesystem basename. Keep the official corpus at
    # HyperSpec/ and expose the same immutable directory for /hyperspec/.
    ln -s HyperSpec "$out/share/common-lisp-hyperspec/hyperspec"

    runHook postInstall
  '';
}
