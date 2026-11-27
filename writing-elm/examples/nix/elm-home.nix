# Lays out an offline ELM_HOME for the Elm compiler, elm-test-rs and
# elm-review inside the Nix sandbox, and returns the shell snippet that does
# it. Evaluation fails, before anything builds, when a project's elm.json asks
# for a different Elm than nixpkgs provides, when its elm-srcs.nix is stale, or
# when two projects pin one package at different versions.
{ pkgs, elm, projects, extraSources ? [ ] }:
let
  inherit (pkgs) lib;

  # Every package and exact version an application's elm.json names.
  pinnedBy = manifest:
    lib.foldl' (acc: section: acc // ((manifest.${section.name} or { }).${section.kind} or { })) { } [
      { name = "dependencies"; kind = "direct"; }
      { name = "dependencies"; kind = "indirect"; }
      { name = "test-dependencies"; kind = "direct"; }
      { name = "test-dependencies"; kind = "indirect"; }
    ];

  checkProject = { elmJson, sources }:
    let
      manifest = builtins.fromJSON (builtins.readFile elmJson);
      wanted = pinnedBy manifest;
      have = lib.mapAttrs (_: info: info.version) sources;
    in
    if manifest."elm-version" != elm.version then
      throw "${toString elmJson} asks for Elm ${manifest."elm-version"}, but nixpkgs provides ${elm.version}. Set \"elm-version\" to ${elm.version} and regenerate its elm-srcs.nix."
    else if wanted != have then
      throw "The elm-srcs.nix beside ${toString elmJson} does not match it. Regenerate it with `elm2nix convert > elm-srcs.nix`."
    else
      sources;

  merge = acc: sources:
    acc // lib.mapAttrs
      (name: info:
        if acc ? ${name} && acc.${name}.version != info.version then
          throw "Elm package ${name} is pinned at both ${acc.${name}.version} and ${info.version}; align the projects on one version."
        else
          info)
      sources;

  packages = lib.foldl' merge { } (map checkProject projects ++ extraSources);

  # elm2nix writes registry.dat, the compiler's package index, from an
  # elm.json without network access. Generating it from every pinned package
  # keeps it complete by construction instead of committing a file that can
  # drift from the sources.
  registryDat = pkgs.runCommand "elm-registry.dat" { nativeBuildInputs = [ pkgs.elm2nix ]; } ''
    cp ${pkgs.writeText "elm.json" (builtins.toJSON {
      type = "application";
      "source-directories" = [ "src" ];
      "elm-version" = elm.version;
      dependencies = { direct = lib.mapAttrs (_: info: info.version) packages; indirect = { }; };
      "test-dependencies" = { direct = { }; indirect = { }; };
    })} elm.json
    elm2nix snapshot
    cp registry.dat "$out"
  '';
in
pkgs.elmPackages.fetchElmDeps {
  elmPackages = packages;
  elmVersion = elm.version;
  inherit registryDat;
}
