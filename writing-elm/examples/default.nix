# Offline, sandboxed production build of the example with nixpkgs' Elm.
#
# elm-srcs.nix pins every package elm.json names. Regenerate it whenever
# elm.json changes (`elm2nix convert > elm-srcs.nix`). Evaluation fails if it is
# stale or if elm.json's "elm-version" differs from nixpkgs' compiler; see
# nix/elm-home.nix. checks.nix runs the formatter, tests and elm-review.
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
  buildPhase = import ./nix/elm-home.nix {
    inherit pkgs elm;
    projects = [{ elmJson = ./elm.json; sources = import ./elm-srcs.nix; }];
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
