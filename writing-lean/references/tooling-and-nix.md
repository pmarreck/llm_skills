# Tooling, trust checks and Nix builds

Checked 2026-11-27. nixpkgs ships Lean 4.35.0 with Lake 5.0.0; the latest
upstream release was 4.36.0. Items marked *verified* were run against Lean
4.35.0 from nixpkgs; the rest come from the
[reference manual](https://lean-lang.org/doc/reference/latest/), its
[release notes](https://lean-lang.org/doc/reference/latest/releases/) and the
tools' own documentation.

## See the goal before choosing a tactic

An agent without an editor cannot see goal states, which is where most wasted
attempts come from. Use one of these instead of guessing:

- **[lean-lsp-mcp](https://github.com/oOo0oOo/lean-lsp-mcp)**, an MCP server
  that exposes goals, diagnostics, hover, a multi-attempt tool and lemma
  search to the agent (`claude mcp add lean-lsp uvx lean-lsp-mcp`; run
  `lake build` first). It is community-maintained, it runs project code (use it
  only on trusted projects), and its remote search tools need network access
  and are rate-limited.
- **[leanprover-community/repl](https://github.com/leanprover-community/repl)**,
  a JSON REPL (`lake exe repl`). A `sorry` in a command returns a proof state
  that later `{"tactic": ..., "proofState": N}` requests advance one step at a
  time. Match the REPL's checkout to the project's toolchain.
- **Plain elaboration.** `lean --json File.lean` (*verified*) prints one JSON
  message per line with positions. Put `trace_state` or a deliberately
  failing `done` where you need to see the goal.

## Find names; never invent them

Invented lemma names are the most common failure in published evaluations of
LLM Lean proofs. Before using a name, confirm it exists in the pinned version:

- `#check List.reverse_reverse` prints the statement or fails.
- `exact?`, `apply?`, `rw?` and `simp?` search the current environment.
  `exact?` and `rw?` stop suggesting deprecated lemmas as of 4.28. Replace the
  search call with the concrete term it prints; do not leave `exact?` in
  committed proofs.
- `#print axioms` and `#print` show what a definition depends on.
- With Mathlib: [Loogle](https://loogle.lean-lang.org/) searches by type
  pattern, [LeanSearch](https://leansearch.net/) by natural language.

Core lemma names changed several times between 4.22 and 4.35 (see
[traps](traps-and-changes.md)). Names from training data or older blog posts
are suspect until `#check` accepts them.

## Lake commands worth knowing

- `lake build`, `lake test`, `lake exe NAME`.
- `lake lint`, with core environment linters since 4.31 and
  `--code-quality` since 4.35.
- `lake shake` (built in since 4.28) reports removable imports. It diagnoses
  dependencies; it proves nothing.
- `lake check` and `lake comparator` (4.35); see trust checks below.
- Since 4.29, `lake update` runs `git clean -xf` in dependency checkouts.
  Never keep local edits inside `.lake/packages`.

## Trust checks, weakest to strongest

The reference manual's
[Validating Proofs](https://lean-lang.org/doc/reference/latest/ValidatingProofs/)
page orders the checks:

1. **The build succeeds.** The kernel accepted every declaration.
2. **`#print axioms THEOREM`** (*verified* output format):
   `'t' depends on axioms: [propext, Classical.choice, Quot.sound]` or
   `'t' does not depend on any axioms`. Those three are Lean's standard axioms.
   `sorryAx` means the proof is incomplete. A name containing `._native.`
   (for example `t._native.native_decide.ax_1_1`) means the result was computed
   by compiled code, which trusts the compiler and every `@[implemented_by]`
   and `@[extern]` replacement.
3. **`lean4checker --fresh`** replays the declarations stored in `.olean` files
   through the kernel.
4. **`comparator`** checks an untrusted solution against a challenge file
   whose theorem statements are fixed, using a permitted-axioms list and, if
   wanted, an independent kernel such as nanoda. Lean 4.35 adds
   `lake comparator --paranoid`, which runs every bundled checker (sandboxed
   with bubblewrap, Linux only).

No checker confirms that a theorem states what you meant. Review every
headline statement and every definition it mentions.

## Nix builds

The fleet requires `nix build`, so Lake runs inside a derivation with no
network access.

- **No dependencies beyond core Lean.** Put nixpkgs' `lean4` in
  `nativeBuildInputs` and run `lake build` or `lean FILE.lean` in the build
  phase. This skill's own `examples/checks.nix` does this.
- **Lake dependencies.** nixpkgs has `leanPackages.buildLakePackage`, which
  takes `src`, `leanDeps` and `lakeHash`
  ([NixOS wiki](https://wiki.nixos.org/wiki/Lean_4)): `lakeHash = null` when
  every dependency is a Nix package, or a fixed-output hash when Lake fetches
  them. The community flake [lean4-nix](https://github.com/lenianiva/lean4-nix)
  builds one derivation per entry in `lake-manifest.json`.
- **Mathlib.** `lake exe cache get` downloads prebuilt `.olean` files and
  needs the network; building Mathlib from source takes a long time. A
  pattern proven in this fleet: one fixed-output derivation, pinned by output
  hash, copies hash-pinned sources of Mathlib's manifest dependencies into
  `.lake/packages`, marks them as local path packages through
  `lake --packages=overrides.json`, runs `lake exe cache get` for only the
  modules the proofs import, and installs only the `.olean` and `.ir` files.
  Proof derivations then build offline with `LEAN_PATH` pointing at that
  output. Pin Mathlib to the commit whose `lean-toolchain` equals the
  project's.
- Keep the Mathlib closure out of the shipped program's runtime closure; it is
  a proof-time dependency.
