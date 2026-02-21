{ stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "sbcl-named-closure";
  version = "local-1";
  src = ./vendor/named-closure;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp named-closure.asd named-closure.lisp "$out/"
    cat > "$out/named-closure-local.asd" <<'EOF'
(asdf:defsystem "named-closure-local"
  :description "Alias system for environments expecting named-closure-local"
  :depends-on ("named-closure"))
EOF
    runHook postInstall
  '';
}
