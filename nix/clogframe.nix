{ pkgs }:

let
  lib = pkgs.lib;

  clogSrc = pkgs.sbclPackages.clog.src;

  darwinFrameworks = pkgs.darwin.apple_sdk.frameworks;

  webkitgtkPackage =
    if pkgs ? webkitgtk_4_1 then pkgs.webkitgtk_4_1
    else if pkgs ? webkitgtk_4_0 then pkgs.webkitgtk_4_0
    else pkgs.webkitgtk;
in
pkgs.stdenv.mkDerivation {
  pname = "clogframe";
  version = "nixpkgs-clog";

  dontUnpack = true;
  dontConfigure = true;

  nativeBuildInputs =
    lib.optionals pkgs.stdenv.isLinux [
      pkgs.pkg-config
    ];

  buildInputs =
    lib.optionals pkgs.stdenv.isDarwin [
      darwinFrameworks.Cocoa
      darwinFrameworks.CoreGraphics
      darwinFrameworks.Foundation
      darwinFrameworks.WebKit
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.gtk3
      webkitgtkPackage
    ];

  buildPhase = ''
    runHook preBuild

    cp -R ${clogSrc}/clogframe "$NIX_BUILD_TOP/clogframe-src"
    chmod -R u+w "$NIX_BUILD_TOP/clogframe-src"

    pushd "$NIX_BUILD_TOP/clogframe-src"

    if [ "${lib.boolToString pkgs.stdenv.isDarwin}" = "true" ]; then
      echo "building CLOG Frame for Darwin"
      $CXX clogframe.cpp \
        -std=c++11 \
        -framework Cocoa \
        -framework CoreGraphics \
        -framework Foundation \
        -framework WebKit \
        -o clogframe
    elif [ "${lib.boolToString pkgs.stdenv.isLinux}" = "true" ]; then
      echo "building CLOG Frame for Linux"
      if pkg-config --exists webkit2gtk-4.1; then
        WEBKIT_PKG=webkit2gtk-4.1
      else
        WEBKIT_PKG=webkit2gtk-4.0
      fi

      $CXX clogframe.cpp \
        -std=c++11 \
        $(pkg-config --cflags --libs gtk+-3.0 "$WEBKIT_PKG") \
        -o clogframe
    else
      echo "Unsupported platform for clogframe." >&2
      exit 1
    fi

    test -x "$NIX_BUILD_TOP/clogframe-src/clogframe"

    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m 0755 "$NIX_BUILD_TOP/clogframe-src/clogframe" "$out/bin/clogframe"

    runHook postInstall
  '';
}
