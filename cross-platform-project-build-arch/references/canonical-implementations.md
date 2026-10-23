# Canonical executable implementations

Use one `./build` entrypoint. Keep the native build graph and Nix packages;
adapt their selection/publication layer instead of replacing working compilers.
This contract applies to projects with independently executable implementations,
not every project containing more than one source language.

## Selection

Track `CANONICAL_IMPL` at the project root. Its entire content is one registered
implementation identifier, optionally followed by one LF. Typical identifiers
are `zig`, `rust`, `lean`, `luajit`, `c` and `elixir`. A mixed Rust/Zig product is
one implementation; distinct implementations in the same language may use
distinct identifiers. Declare identifiers in the existing build configuration,
not by guessing which source directories happen to exist.

`./build canonize rust` validates the identifier, atomically writes the file,
then prints to stdout and exits successfully:

```text
rust implementation canonized. Rerun ./build to rebuild.
```

No compilation, download or public-command switch occurs during canonization.
Repeating the same selection leaves the file unchanged. Never source or eval
the file. Reject empty, unknown, whitespace-padded or multiline contents with
an actionable error. Before an adopting multi-implementation project builds,
require a valid selection; do not silently fall back to a different language.
Ensure a new selection file is Git-tracked so a Git-backed Nix flake sees it.

## Build scopes

The default is canonical implementation, current platform. The two scope flags
are independent, order-insensitive and idempotent:

- `--all-impls` aliases `--all-implementations`.
- `--all-plats` aliases `--all-platforms`.
- `--all` enables both dimensions.

Resolve the scope against the declared implementation/platform support matrix.
A missing required builder is an incomplete/failed build, not an excluded
target invented after failure. Do not combine `canonize` with build-scope flags;
it is a configuration action. Keep help and CLI tests aligned with this table.

## Output and publication

Use project-relative product trees:

```text
rust-out/linux-amd64/gnu/release/bin/tool
rust-out/linux-amd64/musl/release/bin/tool
zig-out/linux-amd64/musl/release/bin/tool
lean-out/macos-arm64/release/bin/tool
bin/linux-amd64/tool -> selected compatible product
```

`VARIANT` is `gnu` or `musl` where applicable, otherwise unset and absent from
the path. Keep it out of PF/PLATFORM and PATH. The build configuration selects
the applicable variant(s); `--all-platforms` does not by itself mean every ABI.
Retain existing explicit profile names. Product trees may also contain `lib`,
`include`, `share` and `Applications`; preserve runtime resources and bundles.

Nix builds implementation packages into its store. Retained output links expose
them under these project paths; do not write through those links or confuse
them with direct-build output prefixes. Keep generated links/products ignored.
Make the selector choose the package rather than making every package depend
on it unnecessarily, so canonization does not force unrelated recompilation.

Only the canonical implementation publishes the project's declared public
commands in `bin/<PF>/`. Other implementations remain directly runnable at
their namespaced paths. Generic `bin/` is for portable scripts. Publishing a
foreign target cannot change the current platform's commands. Reject a missing
required canonical command rather than leaving an accidental mix of languages.

Publish only verified successful products, preserving the previous working
selection on failure. Update only build-managed entries, serialize competing
publishers, and retain rollback for a command set. A changed CANONICAL_IMPL
records intent; until a successful build, installed commands can still be the
previous selection. Preserve Windows DLL adjacency and support publication
without requiring Unix symlink privileges, per the parent skill.

## Migration and proof

1. Inventory implementations, supported targets, commands, existing build-all
   semantics and callers. Preserve a recoverable starting state.
2. Add failing behavioral tests for selection/scope/publication using recording
   build adapters; implement the thin selection layer against the existing graph.
3. During transition `./build --all` may exec legacy `./build-all` only if its
   behavior covers both dimensions. Do not drop profile/target arguments. Never
   also make build-all delegate back to build --all: that creates recursion.
4. Once consolidated, retire build-all recoverably or keep a one-way alias if
   required by actual users. Update CI, run/test helpers and documentation.
5. Run the complete test entrypoint and an actual canonical host build. Report
   which foreign builds/runtimes remain unverified. No automatic fleet rollout.

Required cases, reached through `./test`:

- Scope combinations, short/long aliases, reversed order and repeated flags
  select identical expected sets; unsupported combinations are handled honestly.
- Selection with/without LF; rejected empty/unknown/multiline values; no command
  execution from hostile contents; canonize invokes no builder and changes no
  published command; repeated canonize leaves persisted state unchanged.
- A canonical switch selects the expected executable(s); other implementations
  and platform outputs coexist; missing required commands and forced build
  failures preserve the prior working publication.
- VARIANT present/absent produces the intended paths without ABI collisions;
  paths with spaces work; native target triples reach the actual build adapter.
- Nix sees the tracked selector; product links retain required store outputs;
  no direct build writes into a Nix store link. Pair fake-adapter tests with a
  focused real build/publication check; naming-only assertions are insufficient.
