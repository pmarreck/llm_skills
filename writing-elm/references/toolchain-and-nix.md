# Elm toolchain and Nix builds

Versions and dates were checked on 2026-11-27 against GitHub releases, npm,
package.elm-lang.org metadata and nixpkgs. Rows marked *researched* were not
exercised; everything else was run while writing this skill.

## Compiler

| Version | Released | Notes |
|---|---|---|
| 0.19.1 | 2019-10-21 | The version most tutorials and packages assume |
| 0.19.2 | 2026-07-06 | Faster builds; no language changes ([release notes](https://github.com/elm/compiler/releases/tag/0.19.2)) |
| 0.19.3 | 2026-10-02 | Compiler internals; no language changes ([release notes](https://github.com/elm/compiler/releases/tag/0.19.3)) |
| 0.19.4-beta | tag only | Do not target |

Evan Czaplicki's posts ([faster builds](https://elm-lang.org/news/faster-builds),
[another step towards Elm 1.0](https://elm-lang.org/news/another-step-towards-elm-v1))
describe a sequence of small releases toward 1.0, with `equatable` and
`hashable` types announced but unreleased. The older `roadmap.md` in the
compiler repository predates this and is stale.

**Default policy:** use the newest Elm in the project's nixpkgs pin, built by
Nix together with its matching test runner. Move to a newer release by
advancing the pin. Use the official release binary only when the owner or the
project explicitly needs a release that nixpkgs lacks.

## nixpkgs attributes (nixpkgs master, 2026-11-27)

| Attribute | nixpkgs | Upstream latest |
|---|---|---|
| `elmPackages.elm` | 0.19.2 (built from source with GHC) | 0.19.3 |
| `elmPackages.elm-format` | 0.8.8 | 0.8.8 |
| `elmPackages.elm-test` | 0.19.2-1 | 0.19.3-0 (requires Elm 0.19.3) |
| `elmPackages.elm-test-rs` | 3.2.0 | 3.2.0 |
| `elmPackages.elm-review` | 2.13.5 | 2.13.5 |
| `elmPackages.elm-json` | 0.2.13 | 0.2.13 (dormant since 2022) |
| `elmPackages.elm-language-server` | 2.8.0 | 2.10.0 |
| `elmPackages.elm-watch` | 1.2.9 | 1.2.9 |
| `elm2nix` | 0.4.0 | 0.5.0 |

*Researched:* `elm-pages`, `create-elm-app` and `elm-analyse` were removed from
nixpkgs. Lamdera is a fork with a hosted backend, not stock Elm.

Pin the test runner to the compiler: npm `elm-test` versions are named after
the Elm version they require. `elm-test-rs --compiler "$(command -v elm)"`
runs against whichever compiler is on PATH and was verified with 0.19.2 and
0.19.3.

## Offline builds in the Nix sandbox

The compiler looks for packages under `$ELM_HOME/<its own version>/packages/`,
plus a `registry.dat` package index there. The sandbox has no network, so both
must be supplied:

1. `elm2nix convert > elm-srcs.nix` reads `elm.json` and pins every package
   tarball (including test dependencies) with a hash.
2. `registry.dat`:
   - **Elm 0.19.2:** `elm2nix snapshot` writes a minimal one from `elm.json`.
     Verified working.
   - **Elm 0.19.3:** rejects that file ("Corrupt File ... Error when expecting:
     fewer bytes") and then tries the network. Run the 0.19.3 compiler once
     with network access and a fresh `ELM_HOME`, then commit
     `$ELM_HOME/0.19.3/packages/registry.dat` (about 137 KB). Verified working.
3. `elmPackages.fetchElmDeps { elmPackages; elmVersion; registryDat; }` returns
   a shell snippet that lays both out under a writable `.elm` and exports
   `ELM_HOME`. `elmVersion` must equal the compiler version and `elm.json`'s
   `elm-version`; a mismatch makes the compiler look in the wrong directory.

[examples/default.nix](../examples/default.nix) is a complete, verified
derivation. Regenerate `elm-srcs.nix` and `registry.dat` whenever `elm.json`
changes, and make the project's checks fail when they are stale, for example
by comparing `elm2nix convert` output with the committed file.

The elm2nix `init` template hard-codes `elmVersion = "0.19.1"`; replace it with
the compiler's `version` attribute as the example does.

## Using a release newer than nixpkgs

[examples/nix/elm-release-binary.nix](../examples/nix/elm-release-binary.nix)
packages the official release binary with `fetchurl` and a pinned hash per
platform, and checks `elm --version` in `installCheckPhase`. The x86_64 Linux
binary is statically linked and was verified in the sandbox; the macOS and
ARM assets are pinned but untested. Remember the `registry.dat` rule above.

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
status: 0.19.3 prints "Success! Compiled 1 module." even when it then refuses
to generate output. `elm make --debug` (the time-travel debugger) is a
different feature.

## elm-review

*Researched.* Install the CLI as a pinned dev dependency or from nixpkgs, not
globally. Its configuration is its own Elm project in `review/`, with
`review/src/ReviewConfig.elm` exposing `config : List Rule`. Start from
`elm-review init --template jfmengels/elm-review-config/application` (or
`/package`). Standard rule packages from the elm-review author, with versions
current on 2026-11-27:

- `jfmengels/elm-review-unused` 1.2.6: `NoUnused.Variables`,
  `.CustomTypeConstructors`, `.CustomTypeConstructorArgs`, `.Exports`,
  `.Dependencies`, `.Parameters`, `.Patterns`
- `jfmengels/elm-review-debug` 1.0.8: `NoDebug.Log`, `NoDebug.TodoOrToString`
- `jfmengels/elm-review-common` 1.3.5: `NoMissingTypeAnnotation`,
  `NoExposingEverything`, `NoImportingEverything`
- `jfmengels/elm-review-simplify` 2.1.15: `Simplify`

elm-review has no inline disable comments; configure exceptions for generated
or vendored code. Its review project downloads packages too, so an offline
Nix check needs its dependencies pinned the same way as the application's.

## Project hygiene

- Keep `elm-stuff/` out of version control; it is a build cache.
- Use `elm install` to add or promote a dependency and review the `elm.json`
  diff. Applications pin exact versions of every direct and indirect
  dependency; packages use version ranges and have no indirect section.
- A corrupt shared `~/.elm` cache produces confusing errors. Use a per-project
  or per-job `ELM_HOME` outside Nix, and the derivation's own `.elm` inside it.
