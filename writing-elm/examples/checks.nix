# The example's verification loop, offline in the Nix sandbox: elm-format,
# elm-test-rs and elm-review. default.nix is the production build; a project
# flake exposes both as checks so `nix flake check` runs everything.
{ pkgs ? import <nixpkgs> { } }:
let
  inherit (pkgs) elmPackages;
  elm = elmPackages.elm;
in
pkgs.stdenvNoCC.mkDerivation {
  name = "elm-example-checks";
  src = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = pkgs.lib.fileset.unions [ ./elm.json ./src ./tests ./review/elm.json ./review/src ];
  };
  nativeBuildInputs = [ elm elmPackages.elm-format elmPackages.elm-test-rs elmPackages.elm-review pkgs.nodejs ];
  buildPhase = import ./nix/elm-home.nix {
    inherit pkgs elm;
    projects = [
      { elmJson = ./elm.json; sources = import ./elm-srcs.nix; }
      { elmJson = ./review/elm.json; sources = import ./review/elm-srcs.nix; }
    ];
    # elm-test-rs compiles its runner from this package; see the file.
    extraSources = [ (import ./nix/test-runner-srcs.nix) ];
  } + ''
    export HOME="$TMPDIR"
    elm-format --validate src tests review/src
    elm-test-rs --offline --compiler "$(command -v elm)"
    elm-review --offline --compiler "$(command -v elm)"
  '';
  installPhase = "touch $out";
}
