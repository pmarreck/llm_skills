# OPT-IN ONLY: the official Elm 0.19.3 release binary, pinned by hash, for a
# project that explicitly needs a release newer than nixpkgs (which ships
# 0.19.2 as of 2026-11-27). The default is the compiler from nixpkgs. Verified
# on x86_64-linux (statically linked); the macOS assets are pinned but untested.
# Elm 0.19.3 needs a registry.dat written by itself, not by `elm2nix snapshot`.
{ lib, stdenvNoCC, fetchurl, gzip }:
let
  version = "0.19.3";
  assets = {
    x86_64-linux = { name = "linux-x64"; hash = "sha256-0RcCsxV37YtyC52BxSyKGaUrcrH8+t7w/K2S8heYxYo="; };
    aarch64-linux = { name = "linux-arm"; hash = "sha256-TSLE0Q+J5ILTVUt69PZSf4oF5NgmSKB7I/HyEUlbXSQ="; };
    aarch64-darwin = { name = "mac-arm"; hash = "sha256-pCbkfRTLoFiKqBR1rcMroku/BFIJ0MVg0KiaXE88NNA="; };
    x86_64-darwin = { name = "mac-x64"; hash = "sha256-SpxVeOU8T+tVuRyO6aD0bamRNBTGMD0cVa3Q06vNmSE="; };
  };
  asset = assets.${stdenvNoCC.hostPlatform.system}
    or (throw "elm ${version}: no official binary for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "elm";
  inherit version;
  src = fetchurl {
    url = "https://github.com/elm/compiler/releases/download/${version}/elm-${version}-${asset.name}.gz";
    inherit (asset) hash;
  };
  nativeBuildInputs = [ gzip ];
  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    gzip -dc $src > $out/bin/elm
    chmod 755 $out/bin/elm
    runHook postInstall
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    test "$($out/bin/elm --version)" = "${version}"
  '';
  meta = {
    description = "Elm compiler (official release binary)";
    homepage = "https://elm-lang.org";
    license = lib.licenses.bsd3;
    mainProgram = "elm";
    platforms = builtins.attrNames assets;
  };
}
