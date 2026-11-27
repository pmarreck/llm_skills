---
name: upgrading-zig-16-to-17
description: Plan, investigate, or perform an explicitly authorized Zig 0.16 to 0.17 migration, including the 0.17.1 patch release, Nix dependency staging, semantic compatibility, and native target qualification. Do not upgrade solely because a newer release exists.
---

# Upgrade Zig 0.16 to 0.17

Use this skill alongside `writing-zig` and `writing-nix` when assessing or
performing a 0.16-to-0.17 migration. An assessment is not authorization to
upgrade a project, its dependencies, or the fleet. Respect the owner's current
priorities and the project's existing work, release holds, and PLAN policy.

## Version and evidence

Zig 0.17.1 was announced on 2026-11-03 as a bug-fix release addressing more
than 57 issues reported after 0.17.0, particularly regressions and upgrade
blockers. That is not a claim that every issue is fixed, or that 0.16 code now
compiles unchanged. Check the actual issue, target, and fixed release before
claiming a project-specific blocker is resolved. Prefer exactly 0.17.1 for an
approved 0.17 migration unless the project specifies a different tested target;
do not substitute a 0.18 development compiler.

Consult [the shared 0.16-to-0.17 migration reference](../writing-zig/references/zig-0.16-to-0.17.md)
for the detailed source, build-system, ABI, and semantic changes. Check any
version-specific example against the actual pinned patch release and its
standard library; a 0.17.0 observation is not proof of behavior in 0.17.1.

## Evaluate before committing to the work

1. Inspect the project's intent, current work and Git status. Determine the
   exact compiler used by each Nix build, dev shell, cross-target and consumer;
   a ZON minimum version, a package's version, a flake input, or a comment is
   not proof of the compiler selected in a derivation.
2. Identify why the migration matters now: a reproduced compiler defect,
   dependency constraint, required platform, security or measurable benefit.
   Preserve pending changes and separate migration from feature work. Report
   estimated work and blockers; keep deferred work out of an immediate PLAN
   unless the owner agrees to that commitment.
3. Inventory direct and transitive Zig libraries, shared sources, generated C
   bindings and downstream consumers. Agree on an order with the relevant
   owners. A shared library's 0.17-only release can strand a 0.16 consumer;
   prove compatibility at the actual pinned revisions before repinning.

Dependency drift can itself justify a timely assessment: upstream projects may
adopt 0.17 and stop delivering updates usable by 0.16 consumers. Record which
useful updates are blocked, their actual compiler requirements, impact and
available fixes. A dependency's declared `minimum_zig_version` may be stale;
verify its source and build rather than trusting the declaration alone. Do not
silently bypass dependency-freshness policy or infer that all updates are
blocked from a single example.

## Migrate and qualify an approved change

1. Record the original compiler, lockfiles, dependency hashes, test result,
   supported platforms and a recoverable source baseline. Reproduce any
   specific blocker before saying 0.17.1 fixed it. Use an isolated workspace
   appropriate to the existing branch/worktree limits and preserve user work.
2. Pin the exact compiler through the project's Nix source and lock it. Check
   all build paths, not just the interactive shell. Avoid incidental input
   updates; keep dependency and toolchain changes explainable and reviewable.
3. Update build and source APIs using the versioned reference. Pay particular
   attention to the `containsAtLeastScalar` parameter-order change, vector
   bitcasts, reflection data, allocator lifetime, `@cImport`/`translate_c`,
   and the configurer/maker build split: a successful compile alone does not
   establish equivalent behavior.
4. Update ZON source pins and hashes, Nix fixed-output dependency hashes and
   source filters only as the dependency graph requires. Follow `writing-nix`
   and `fix-zig-deps-hash`; check the clean build without ambient host caches.
5. Run the complete project test entry point and `nix build`, including
   relevant semantic regression cases, C ABI/layout checks and packaged
   executable smoke tests. Cross-build supported targets and execute on native
   runners when available. Report separately what compiled and what actually
   ran; keep failures and untested targets visible.
6. Check the current ZLS pairing and editor behavior rather than assuming a
   patch release is compatible. Compare performance and memory on affected hot
   paths when the compiler or generated code can change them. Retain the 0.16
   baseline and rollback path until the upgraded result is qualified.

For a fleet migration, pilot one small, well-tested provider before moving
critical consumers. Coordinate with project owners and carry actual evidence
forward; do not require all projects to migrate at once or bypass freshness,
security, correctness, or release controls.

## Sources

- [Zig 0.17.1 announcement](https://ziglang.org/news/0.17.1-released/)
- [Zig download index](https://ziglang.org/download/)
- [Zig 0.17.1 language reference](https://ziglang.org/documentation/0.17.1/)
- [ZLS release compatibility](https://zigtools.org/zls/releases/)
