---
name: writing-zig
description: Write, test, review, migrate, or debug Zig code and build scripts. Use for Zig language, standard-library, build-system, package, allocator, C ABI, performance, and compiler-version work; establish the project's pinned Zig version before applying any API guidance.
---

# Writing Zig

Treat Zig's compiler version as part of the source contract. Zig is still
pre-1.0 and releases can change language, standard-library, package, and build
APIs substantially. Never infer an API from memory or from an unversioned
example.

## Establish the project's actual toolchain first

1. Read the project `AGENTS.md`, `INTENT.md`, `PLAN.md`, `flake.nix`, lockfile,
   `build.zig.zon`, and any version-specific Zig guide before substantive work.
2. Determine the compiler actually selected by the flake. Use the project's
   Nix path, for example `nix develop -c zig version`, and build through
   `nix build`. Do not use a global Zig binary or a populated host cache as
   proof of the pinned build.
3. Read only API guidance matching that exact Zig version. Older snippets are
   migration clues, not current templates. When guidance conflicts, verify
   against the versioned release notes, language reference, standard-library
   source and a minimal compile using the pinned compiler.
4. Keep toolchain changes separate from feature changes. Do not upgrade a
   project merely because a newer stable compiler exists; record the baseline,
   migrate one project at a time, and run its complete test/build contract.

## Current version map

As of 2026-11-05, Zig `0.17.1` is the latest stable release. It was announced
November 3 as a 0.17.0 bug-fix release; verify individual issues before
claiming they are resolved. Development builds are on 0.18. For an authorized
0.16-to-0.17 migration, use `upgrading-zig-16-to-17` and [the interim migration
reference](references/zig-0.16-to-0.17.md).

The owner's Obsidian `ZIG_RECENT_API_CHANGES.md` is a detailed historical
quick reference for projects pinned to 0.14–0.16. Its 0.16 section is not a
0.17 guide. Preserve its version scope; do not silently rewrite old examples
as universal advice. Use the pinned project's own notes and the migration
reference for newer work.

For a new Zig repository, also invoke `scaffold-zig-project`. That skill owns
greenfield project layout and initial wiring; this skill owns language/API
correctness. Review generated templates against the selected compiler and
current Nix policy before using them.

## Implementation discipline

- Follow TDD: write a focused failing test for behavior, confirm the red phase,
  implement the smallest correction, then run the complete `./test` and
  canonical `nix build` paths. Zig tests only run when reachable from a test
  root; ensure each test-bearing module is included and has its own test
  artifact when it is a separate build module. A filtered run that reports
  zero matching tests is not evidence.
- Keep pure decoding and business logic separate from I/O. Pass allocators,
  `std.Io`, clocks, randomness and external effects explicitly where the
  selected API permits it. Use `ReleaseSafe` for tests and `ReleaseFast` for
  shipped artifacts unless the project has a stronger verified policy.
- Initialize every field after raw allocation such as `allocator.create(T)`;
  struct field defaults apply to struct-literal construction, not raw memory.
  Prefer a complete struct literal where lifetime and pointer-stability rules
  permit it.
- Make integer widths explicit around arithmetic, shifts, `@min`/`@max`, and
  parsed lengths. Never rely on inferred narrow result types where later math
  requires a wider type. Keep safety checks enabled in tests so overflow,
  bounds and cast errors remain observable.
- For C ABIs, pass arbitrary bytes as pointer-plus-length, not as C strings.
  Document ownership, allocator pairing, lifetime, nullability, alignment,
  error representation and thread-safety. Do not allow Zig errors, panics,
  Rust panics or C++ exceptions to unwind across a C boundary.
- Do not silently downgrade failed concurrency or reference-tool setup. A
  fallback that preserves correctness but removes parallelism must be visible
  and covered by a performance check.
- Run cross-target build and packaged-artifact smoke checks for every supported
  platform. A successful compile does not prove the loader, libc, ABI, or
  runtime dependencies are usable. For the Linux libc choice, see "Linux libc
  and dead code" below.

## Dependencies and Nix

For interchangeable cores or CLIs that must exercise a public ABI, use
[multi-implementation-contracts](../multi-implementation-contracts/SKILL.md).
An internal Zig module import does not test whether external consumers can
use the exported library.

Nix is required. Before adding or changing Zig dependencies, follow
[`writing-nix`](../writing-nix/SKILL.md), especially its
[dependency portability reference](../writing-nix/references/dependency-portability.md).
That reference is authoritative for choosing between a ZON package, a pinned
flake input, and Nix-staged source; it also defines Zig package hashes versus
Nix fixed-output hashes, transitive cache prefetching, private sources, and
clean source-bounded builds. Do not duplicate or weaken it here.

Use the compiler source already selected by the project. A shared fleet memory
records `zig-overlay` as the usual exact-version source, but inspect the
current flake rather than assuming an old memory overrides its actual pin.
Keep language package metadata and Nix fetch/cache inputs synchronized. Never
depend on a host's global Zig cache, a sibling checkout, a local file URL, or a
literal Nix-store path. Run the complete derivation after changing dependency
staging; a devShell-only build is insufficient.

Use `fix-zig-deps-hash` only for a genuine dependency-content change. A moved
URL or tag does not by itself prove the package contents changed.

## Linux libc and dead code

Each project uses one libc for all of its Linux builds. Static musl is the
default; dynamic glibc is for programs that must load host GPU, display or
audio libraries. Neither may depend on a Nix store path. The policy, the
reasons (never static glibc) and the blocking gate live in
[writing-nix's runtime-independence gate](../writing-nix/references/consuming-build-outputs.md).
These are the Zig mechanics, verified on Zig 0.16.0.

- **Static musl:** build for `-Dtarget=<cpu>-linux-musl`. Zig bundles musl
  and links the executable statically, so there is no interpreter to
  repoint. The native gnu target on NixOS instead yields a dynamic glibc
  binary whose baked-in FHS loader path does not exist there, which is why
  projects reach for `patchelf`.
- **glibc:** name the target and its glibc floor explicitly, for example
  `-Dtarget=x86_64-linux-gnu.2.28`. Zig then uses its own glibc stubs for
  that version rather than the build host's glibc. An explicit gnu target
  gets the standard `/lib64/ld-linux-x86-64.so.2` interpreter and no
  RUNPATH. With `.2.28`, a glibc 2.38 function (`strlcpy`) was undeclared at
  compile time; with `.2.39` it linked, and the newest symbol version was
  `GLIBC_2.38`. An unversioned gnu target also refused it, so state the
  floor rather than rely on the default. Confirm the result with the
  writing-nix gate.
- Archives a program links (C or Rust) must be built for the same libc.
- Zig code is compiled lazily, so a function nothing references gets no code.
  A static library is different: every `export fn` is a root, so the whole
  exported surface is emitted. Set `lib.link_function_sections = true` and
  `lib.link_data_sections = true` on shipped libraries so that a consumer's
  `--gc-sections` can drop exports it never calls.
- C sources added with `addCSourceFile` need `-ffunction-sections` and
  `-fdata-sections` in their flags. Set `exe.link_gc_sections = true` on the
  executable rather than relying on the optimize-mode default.
- Strip debug information from shipped executables (`strip --strip-debug` in
  the package, or the module's `strip` option). Keep the symbol table when
  tests inspect it with `nm`.
- Measure rather than assume. In one CLI (x86_64, ReleaseFast), the section
  flags dropped two unused exports, 720 bytes of a 461 KB executable, because
  lazy compilation had already removed the rest. Static musl added about
  63 KB of code. Stripping debug information mattered most: the file went
  from 1.9 MB to 461 KB.

## Performance and deeper checks

For hot paths, establish a repeatable optimized baseline before considering
algorithm changes, SIMD, LLVM-level tuning, or cache changes. Use
[`performance-profiling`](../performance-profiling/SKILL.md) for `./bm`,
`./big_o`, memory growth, history and acceptance rules. Measure before and
after; include correctness and cross-platform dispatch checks for SIMD.

For risky parsers and decoders, add bounded fuzzing and differential tests
where useful, but put fixed regressions and acceptance-critical checks in
`./test`. Verify that malformed inputs return structured errors rather than
crashing or silently accepting invalid data.

## Fleet lessons worth checking

The shared memory root contains evidence-backed Zig findings. Search its
metadata before debugging a familiar-looking failure, especially for:

- Zig 0.16 `std.Io` and process-spawn setup;
- `Thread.spawn` with libc and too-small stacks;
- `@min`/`@max` result-width refinement;
- allocator-created uninitialized structs;
- unreachable module tests and false-green filtered runs;
- C translation gaps such as `_Atomic` parameters and `char **` out-parameters;
- Linux loader/static-link requirements;
- stale cross-checkout Zig caches;
- Nix Darwin SDK linker flags; and
- stdlib checksums that are read but not verified.

Use the `memories` skill to retrieve the exact evidence before applying a
lesson. Memories are diagnostic leads, not substitutes for reproducing the
issue under the project's pinned compiler.

When a Zig-specific failure repeats, add a concise, versioned lesson to the
appropriate project or shared memory and improve this skill or its references
only when the evidence generalizes. Do not record speculative fixes as rules.
