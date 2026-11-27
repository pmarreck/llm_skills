# Elm toolchain and Nix builds

Versions were checked on 2026-11-27. Rows marked *researched* were not
exercised; everything else was run while writing this skill, and the example's
build and checks run in this repository's CI.

## Compiler

| Version | Released | Notes |
|---|---|---|
| 0.19.1 | 2019-10-21 | The version most tutorials and packages assume |
| 0.19.2 | 2026-07-06 | Faster builds; no language changes ([release notes](https://github.com/elm/compiler/releases/tag/0.19.2), [announcement](https://elm-lang.org/news/faster-builds)) |

**Policy:** use the Elm in the project's nixpkgs pin, built by Nix together
with the matching tools. Move to a newer release by advancing the pin.

## nixpkgs attributes (nixos-unstable, 2026-11-21)

| Attribute | Version |
|---|---|
| `elmPackages.elm` | 0.19.2 (built from source with GHC) |
| `elmPackages.elm-format` | 0.8.8 |
| `elmPackages.elm-test-rs` | 3.2.0 |
| `elmPackages.elm-test` | 0.19.2-1 |
| `elmPackages.elm-review` | 2.13.5 |
| `elmPackages.elm-json` | 0.2.13 (dormant since 2022) |
| `elmPackages.elm-language-server` | 2.8.0 |
| `elmPackages.elm-watch` | 1.2.9 |
| `elm2nix` | 0.4.0 |

*Researched:* `elm-pages`, `create-elm-app` and `elm-analyse` were removed from
nixpkgs. Lamdera is a fork with a hosted backend, not stock Elm.

Use `elm-test-rs`: it runs offline with `--offline`, against the compiler
named by `--compiler`, and the example runs it that way in the sandbox. The
npm-style `elm-test` is named after the Elm version it requires; it was not
tried offline.

## Offline builds and checks in the Nix sandbox

The compiler and its tools look for packages under
`$ELM_HOME/<compiler version>/packages/`, with a `registry.dat` package index
beside them. The sandbox has no network, so everything must be supplied. The
example does it in three files; copy them:

- **`nix/elm-home.nix`** merges the pinned packages of every Elm project (the
  application and `review/`) plus extra sources, and lays out `ELM_HOME` with
  `elmPackages.fetchElmDeps`. Evaluation fails, before anything builds, when
  an `elm.json`'s `elm-version` differs from nixpkgs' compiler, when an
  `elm-srcs.nix` no longer matches its `elm.json`, or when two projects pin
  one package at different versions. It generates `registry.dat` with
  `elm2nix snapshot` from all the pinned packages; that command needs no
  network, so there is no committed `registry.dat` to go stale.
- **`default.nix`** is the production build.
- **`checks.nix`** runs `elm-format --validate`,
  `elm-test-rs --offline --compiler "$(command -v elm)"` and
  `elm-review --offline --compiler "$(command -v elm)"`, with `HOME` set to
  the build directory. Each of these was shown to fail the check when given
  a misformatted file, a failing test or a review finding.

Generate each project's sources with `elm2nix convert > elm-srcs.nix` in the
directory that holds its `elm.json`; it pins every package, test dependencies
included. elm-test-rs also compiles its runner from
`mpizenberg/elm-test-runner`, which no `elm.json` lists, so
`nix/test-runner-srcs.nix` pins it by hand (6.0.1 for elm-test-rs 3.2.0).
When nixpkgs updates elm-test-rs and it reports "there is no version of
mpizenberg/elm-test-runner in X", pin version X there.

Expose both derivations from the project flake so `nix flake check` and
`./test` run everything:

```nix
packages.default = import ./default.nix { inherit pkgs; };
checks.build = import ./default.nix { inherit pkgs; };
checks.elm = import ./checks.nix { inherit pkgs; };
```

Do not start from `elm2nix init`: its template hard-codes
`elmVersion = "0.19.1"` and expects a committed `registry.dat`.

## Production builds

The official recipe ([asset size guide](https://guide.elm-lang.org/optimization/asset_size.html),
[compiler hint](https://github.com/elm/compiler/blob/main/hints/optimize.md)):

```bash
elm make src/Main.elm --optimize --output=elm.js
uglifyjs elm.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | uglifyjs --mangle --output elm.min.js
```

`uglifyjs` must run twice; the guide notes it otherwise ignores `pure_funcs`.
The example shrank from 157 KB to 31 KB this way. The official docs name only
uglify-js; terser or esbuild recipes are community advice, and
elm-optimize-level-2 is low-activity with unverified support for newer
compilers.

`--optimize` shortens record field names and unboxes single-constructor
types, which is why it refuses any use of the `Debug` module. Check the exit
status: Elm prints "Success! Compiled N modules." even when it then refuses
to generate output. `elm make --debug` (the time-travel debugger) is a
different feature.

## elm-review

Run elm-review on all Elm code you write or change. The configuration is its
own Elm project in `review/`, with `review/src/ReviewConfig.elm` exposing
`config : List Rule`. A project without one needs one added; running
`elm-review --template jfmengels/elm-review-config/application` against a
project with no local configuration fails with ELM VERSION MISMATCH, because
the downloaded template targets 0.19.1. Set it up once, outside the sandbox
and with network access:

1. `elm-review init --template jfmengels/elm-review-config/application`
   (`/package` for packages). The template enables the elm-review author's
   recommended rules from `jfmengels/elm-review-common`, `-debug`, `-unused`,
   `-simplify`, `-code-style` and `-documentation`; the example keeps all of
   them.
2. Set `review/elm.json`'s `"elm-version"` to the compiler's version. The
   template writes `0.19.1`, which fails with ELM VERSION MISMATCH under
   0.19.2.
3. `cd review && elm2nix convert > elm-srcs.nix`, and add the project to
   `checks.nix` as the example does. Where the review project and the
   application share a package, they must use the same version.

Run `elm-review --fix` locally to apply the automatic fixes it offers. It has
no inline disable comments; exempt generated or vendored code in the
configuration with `Rule.ignoreErrorsForDirectories` or
`Rule.ignoreErrorsForFiles`.

## Project hygiene

- Keep `elm-stuff/` out of version control; it is a build cache.
- Use `elm install` to add or promote a dependency and review the `elm.json`
  diff. Applications pin exact versions of every direct and indirect
  dependency; packages use version ranges and have no indirect section.
- A corrupt shared `~/.elm` cache produces confusing errors. Use a per-project
  `ELM_HOME` outside Nix, and the derivation's own `.elm` inside it.
