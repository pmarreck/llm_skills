# Offline, sandboxed build of the example with the Elm compiler from nixpkgs.
#
# Packages come from elm-srcs.nix and registry.dat, both generated from
# elm.json by elm2nix. Regenerate them whenever elm.json changes:
#
#   elm2nix convert > elm-srcs.nix && elm2nix snapshot
#
# elm.json's "elm-version" must equal the compiler's version. To use an Elm
# release newer than nixpkgs, see nix/elm-release-binary.nix and the registry.dat
# caveat in references/toolchain-and-nix.md.
{ pkgs ? import <nixpkgs> { } }:
let
  elm = pkgs.elmPackages.elm;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "elm-example";
  version = "0.1.0";
  src = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = pkgs.lib.fileset.unions [ ./elm.json ./src ];
  };
  nativeBuildInputs = [ elm pkgs.uglify-js ];
  buildPhase = pkgs.elmPackages.fetchElmDeps {
    elmPackages = import ./elm-srcs.nix;
    elmVersion = elm.version; # must equal elm.json's "elm-version"
    registryDat = ./registry.dat;
  } + ''
    elm make src/Main.elm --optimize --output=elm.js
    uglifyjs elm.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" \
      | uglifyjs --mangle --output elm.min.js
  '';
  installPhase = ''
    mkdir -p $out
    cp elm.min.js $out/
  '';
}
