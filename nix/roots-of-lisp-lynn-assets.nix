{ lib, runCommand, fetchurl }:

let
  lispHtml = fetchurl {
    url = "https://crypto.stanford.edu/~blynn/lambda/lisp.html";
    hash = "sha256-xI+xZskzqXVF+Enh0rNgBa9fFkS+GxVDMqFg97QmfgE=";
  };
  replyJs = fetchurl {
    url = "https://crypto.stanford.edu/~blynn/compiler/reply.js";
    hash = "sha256-I70fWTDFV2VasecfzaLr4g2NTvSUfK2py2ZIwNCgKDo=";
  };
  runmeJs = fetchurl {
    url = "https://crypto.stanford.edu/~blynn/compiler/runme.js";
    hash = "sha256-4ppvKIodJfbLJS5j0ROBkA2NnGB6HV1c/SB4L+1+NKY=";
  };
  runmeCss = fetchurl {
    url = "https://crypto.stanford.edu/~blynn/compiler/runme.css";
    hash = "sha256-WYlgDjAG0TlggHBJ5yfLjkEEQh/kTi2031sH7jeQHNM=";
  };
  dohWasm = fetchurl {
    url = "https://crypto.stanford.edu/~blynn/compiler/doh.wasm";
    hash = "sha256-qOJjT1yYBUlTetQSSGqePIz5jLEFeZdIP8sYcvHv1Ak=";
  };
  charserOb = fetchurl {
    url = "https://crypto.stanford.edu/~blynn/compiler/Charser.ob";
    hash = "sha256-hgob2jXJPY+ySb7dNRimP8UbD4+i6orRGL3OuqjR5lA=";
  };
in
runCommand "roots-of-lisp-lynn-assets-2026-07-25" {
  passthru = {
    compilerSourceCommit = "a1f1c47c9bb3ff6a45a0735ced84984396560535";
    license = lib.licenses.bsd3;
  };
  meta = {
    description = "Pinned browser runner assets for Ben Lynn's Roots of Lisp demonstration";
    homepage = "https://crypto.stanford.edu/~blynn/lambda/lisp.html";
    license = lib.licenses.bsd3;
  };
} ''
  install -D -m 0444 ${lispHtml} "$out/roots-of-lisp-lynn/lambda/lisp.html"
  install -D -m 0444 ${replyJs} "$out/roots-of-lisp-lynn/compiler/reply.js"
  install -D -m 0444 ${runmeJs} "$out/roots-of-lisp-lynn/compiler/runme.js"
  install -D -m 0444 ${runmeCss} "$out/roots-of-lisp-lynn/compiler/runme.css"
  install -D -m 0444 ${dohWasm} "$out/roots-of-lisp-lynn/compiler/doh.wasm"
  install -D -m 0444 ${charserOb} "$out/roots-of-lisp-lynn/compiler/Charser.ob"
''
