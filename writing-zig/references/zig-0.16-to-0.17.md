# Interim migration: Zig 0.16 to 0.17

Status: source-reviewed interim checklist, not an exhaustive compatibility
matrix. The 0.17.0 API review was last checked 2026-11-02; the 0.17.1 release
announcement was checked 2026-11-05. For a new approved migration prefer exact
`0.17.1`, and verify each API and fix against that patch. Do not substitute a
0.18 development build. No project is migrated merely by reading this guide.

Zig 0.17.0 was announced October 2, 2026. The download page dates the
artifacts October 1. Zig announced 0.17.1 on November 3, addressing more than
57 issues reported after 0.17.0. The 0.17 release changes both the language and
standard library and the build execution model; 0.17.1 does not eliminate the
need to migrate. Keep the 0.16 baseline green, pin 0.17.1, make small edits,
and rerun complete tests and builds.

## High-impact source changes

| 0.16 code | 0.17 action |
|---|---|
| `std.builtin.Type` reflection | Prefer `std.lang.Type`; reflection uses parallel arrays such as `.field_names`, `.field_types`, `.field_attrs`, `.field_values`, `.decl_names`, and enum `.mode`. Preserve attributes/defaults/alignment consumed by the old code. |
| `std.builtin.OptimizeMode`; `.Debug`/`.ReleaseFast` tags | Prefer `std.lang.Optimize`; enum tags are lowercase `.debug`, `.safe`, `.fast`, `.small`. Aliases do not make old inferred enum tags valid. |
| `std.heap.DebugAllocator` / `std.heap.Check` | Both are deprecated; `std.heap.SafeAllocator` is the 0.17 replacement. Recheck allocator options, thread-safety, leak reporting and test expectations rather than renaming blindly. |
| `std.heap.StackFallbackAllocator` / `std.heap.stackFallback` | Replaced by `std.heap.BufferFirstAllocator`; provide the caller-owned buffer explicitly and verify alignment/lifetime. |
| `@intFromEnum` / `@enumFromInt` | Deprecated in favor of `@backingInt` / `@fromBackingInt`; check invalid-tag safety behavior and backing integer types. |
| `@cImport` | Removed. Use the separately pinned `translate_c` package/API. `b.addTranslateC` remains deprecated in 0.17; do not confuse the build helper's deprecation with `@cImport` removal. |
| `run.addArgs(args)` from `b.args` | Use `run.addPassthruArgs()`; passthrough arguments are not available to configure-time logic. |
| `b.findProgram(names, paths)` | Use the 0.17 options form and account for its optional result. `findProgram` can poison configuration caching; prefer lazy discovery when configure-time branching is unnecessary. |
| `b.build_root` | Use `b.root`; recheck `Cache.Path` APIs and path ownership. |
| `Ast.parse(allocator, source, .zig)` | Third argument is `ParseOptions`; use `.{}` for normal Zig parsing and set `.mode = .zon` for ZON. |
| old ZON `fromSliceAlloc`/`fromSlice` ownership | Use the new options-based parser API. Understand arena ownership of result and diagnostics; do not retain old recursive-free assumptions. |
| `std.hash.Crc32Jamcrc` | Use the renamed namespaced CRC type and preserve the algorithm parameters, especially JAMCRC's zero output XOR. |
| array repetition `**`, `void{}`, `errdefer |err|`, `i0` | These syntaxes/types are removed. Use an explicitly typed array plus `@splat` for scalar repetition; use `{}` for void; capture the error at an outer `catch`; review zero-width integer intent. |

Audit every `@bitCast` involving vectors/arrays. 0.17 defines logical,
endian-independent bit behavior; it is not automatically a native-memory
reinterpretation. Extern structs/unions reject vector fields, and `@hasDecl`
checks public declarations only. For ABI layouts, prove size, alignment and
field offsets with explicit tests instead of assuming a cast preserves memory
representation.

Review standard-library renames semantically, not just mechanically. A
particularly dangerous example is `std.mem.containsAtLeastScalar`: the old
deprecated function was removed and the replacement took its name, but two
numeric parameters swapped positions. Existing calls can still compile while
returning a different result. Find all calls and assert argument meaning and
behavior against representative fixtures.

## Build-system and package migration

0.17 separates the `build.zig` configurer process from the maker process and
introduces the Build Server Protocol. Build configuration is serialized and
cached; configure-time side effects or discovery can poison that cache.

- Declare configure-time file, metadata, or directory dependencies explicitly.
- Prefer `findProgramLazy` when a discovered executable is consumed by a build
  step rather than needed to choose configuration immediately.
- Check `Step.Run` response-file behavior, `addPassthruArgs`, install-path APIs,
  and lazy dependency fetching. Some 0.17 build-system migration details are
  still harder to find in the docs than ordinary language changes.
- Do not copy the old Zig `build-all`/direct-build setup into a project. Nix
  remains the canonical build and dependency source; consult `writing-nix` for
  how the pinned toolchain, ZON package hashes, transitive cache, and Nix
  fixed-output hashes fit together.
- Verify the actual ZLS version supports 0.17 before upgrading editor tooling.
  Early post-release reports described missing 0.17 support and incomplete
  build-server integration; recheck current status rather than assuming those
  reports still apply.

## Release-noted regression checks

The 0.17.0 release notes explicitly list known bugs. Before migration, scan the
current regression list for the project's targets/features. At release, noted
examples included soft-float x86 compiler-rt, `std.debug.simple_panic`, weak
Zig-libc symbol overrides, `Step.Run` response files after the process split,
and SPIR-V backend regressions. LLVM 22's loop-vectorization workaround also
remains enabled because the LLVM fix was not in the shipped version.

These are release-time observations, not guaranteed current status. Check the
linked issue or current release notes for fixes and target applicability.

## Migration sequence

1. Record the current 0.16 compiler revision, lockfile, derivation result,
   complete test result, and supported target builds.
2. Update only the compiler pin to exact 0.17.1. Keep dependencies unchanged
   initially where possible; identify packages whose build scripts or minimum
   version block the transition.
3. Fix compiler diagnostics in small groups. Add regression tests for
   semantic changes that compile without error, particularly parameter-order,
   integer-width, `@bitCast`, reflection metadata, and ABI layout changes.
4. Update Nix dependency staging and hashes only for inputs whose content or
   build graph actually changed. Verify clean, source-bounded builds with no
   ambient host cache.
5. Run the whole `./test`, optimized `nix build`, target cross-builds, and
   packaged-program smoke tests. Execute where native runners exist; list
   unexecuted targets honestly.
6. Check ZLS/editor support, incremental compilation if enabled, generated C
   bindings, and app packaging. Compare the full migration against the 0.16
   baseline before landing it.

For fleet rollout, start with one non-critical Zig library that has good tests
and few consumers. Do not migrate every dependent library at once. Land a
passing shared dependency update on its main branch, then update consumers
forward according to the fleet dependency policy.

## Evidence and sources

- [Zig 0.17.0 release announcement](https://ziglang.org/news/0.17.0-released/)
- [Zig 0.17.1 release announcement](https://ziglang.org/news/0.17.1-released/)
- [Zig 0.17.0 release notes](https://ziglang.org/download/0.17.0/release-notes.html)
- [Zig 0.17.0 language reference](https://ziglang.org/documentation/0.17.0/)
- [Zig download index](https://ziglang.org/download/)
- [Ziggit: 0.17 parameter-order footgun](https://ziggit.dev/t/footguns-on-stdlib-renamings-containsatleastscalar/17855)
- [Ziggit: early 0.17 migration blockers and build-system/ZLS reports](https://ziggit.dev/t/anyone-unable-to-upgrade-to-0-17-0-for-some-reason/17912)
- [Ziggit: 0.17 source-level migration examples](https://ziggit.dev/t/what-are-we-expecting-in-0-17/17438)

Forum posts report real experiences, not normative API contracts. Confirm fixes
against the exact compiler tag and a reproducer before changing code.
