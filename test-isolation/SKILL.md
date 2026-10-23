---
name: test-isolation
description: Prevent tests from mutating live project, user or service state. Use for filesystem/process integration tests, build publication or canonize tests, fixture cleanup, sandbox boundaries, or incidents where tests wrote outside disposable resources. Performance timing belongs to performance-profiling.
---

# Test side-effect isolation

Tests own disposable resources, not the working environment. A successful test
must not select the developer's canonical implementation, replace a live command,
change installed applications, or send real messages. A failing test must not do
those things either. Global guidance delegates the detailed contract here.

## Choose the boundary before running

- Pure logic uses injected clocks, RNG and state-collecting I/O adapters.
- Real filesystem adapters get a unique per-test directory beneath TMPDIR.
  Tests of project mutation get a disposable project tree including its selector,
  publication links and output trees. Source fixtures are immutable inputs;
  copy them before mutation. Never run `build canonize`, install, cleanup or
  publication tests against the working checkout or installed product.
- Set private HOME, XDG config/data/state/cache/runtime, application paths and
  database paths. Stub mail, notifications, cloud APIs and agent wakes. A different
  cwd or TMPDIR alone does not redirect absolute paths or symlink destinations.
- Copy fixtures without hardlinking mutable data to the original. Inspect copied
  symlinks; relative paths, `..`, absolute paths and ancestor symlinks can escape.
  String-prefix checks and before/after snapshots are not preventive boundaries.
- Cleanup may remove only the exact resource created by that test invocation.
  Fail setup before running the test if allocation fails; never let an empty path,
  inherited variable or shared name become a cleanup target. Preserve useful
  failure evidence explicitly without restoring over concurrent developer edits.

## Separate preparation from exercising side effects

One `./test` entrypoint still owns the full suite. Prepare dependencies and exact
test binaries once through `nix build`, using declared package/check outputs and
the existing resource budget. Then execute behavioral tests in confinement.
Language compilers run inside derivations; do not maintain a direct-build test
preparation fallback. A check derivation may execute its suite directly without
recursively invoking the outer Nix preparation wrapper.
Preparation is not permission to publish into live `bin/` or modify CANONICAL_IMPL.
Test the real build/publication adapter using disposable roots and prepared
artifacts; isolate build caches when their mutation is itself under test.

Do not reenter a shared build queue merely to recheck an already-built executable.
Preserve admission limits; reuse the admitted job or artifacts instead of bypassing
caps. Follow [performance-profiling](../performance-profiling/SKILL.md) for queue,
compile and execution timing. Slow end-to-end feedback is visible even when
execution alone meets budget; quiet mode must not swallow long queue waits.

## Linux preventive gate

`scripts/run-isolated -- COMMAND ARGS...` uses Bubblewrap to present the host
filesystem read-only, with private tmpfs scratch, HOME/XDG paths, process/network
namespaces and dropped capabilities. The current project remains readable at its
original path. `TEST_WORKSPACE` names writable scratch for disposable project
copies. Retargeting a scratch symlink to the real project still encounters a
read-only mount. The command's exit status propagates.

Provide Bash, coreutils and Bubblewrap through the project's pinned Nix
environment. Run from a project directory, not `/` or `/tmp`. Invoke Nix/build
preparation outside this gate; the private `/run` deliberately hides service
sockets including the Nix daemon. An illustrative execution phase is:

```bash
run-isolated -- bash -c 'cp -R ./tests/fixtures/project "$TEST_WORKSPACE/project" && cd "$TEST_WORKSPACE/project" && ./build canonize rust'
```

Check copy/setup failures explicitly in real test scripts. Fixture scripts must
be actual scoped adapters or controlled fixtures, not a copy of business logic
invented to agree with itself. A project integrating the helper must also include
its forbidden-write canaries and real adapter regression in the complete suite.

Missing Bubblewrap, unavailable namespaces or unsupported operating systems
must refuse execution; never silently retry unconfined. This helper is Linux-only.
On macOS/Windows use a separately qualified OS boundary, disposable VM/user
environment, or a Nix check with the required isolation. Private directories and
injected I/O remain required everywhere; they alone are not OS enforcement.
Do not claim cross-platform enforcement until tested on those platforms.

Limits: this is accidental filesystem-write prevention, not a hostile-code or
secret-read sandbox. Other readable host paths remain visible. Accessible Unix
sockets or inherited standard streams can convey effects outside filesystem
write checks; do not provide live service channels/credentials. The helper gives
no writable host-directory exceptions. Scratch disappears when the namespace
ends; return evidence through captured output or an explicitly designed exporter.
A program may catch a denied write and return success: test the expected refusal
and unchanged target explicitly rather than claiming every attempted write forces
a nonzero test result. No deployment or global tool interception is implied.

## Controls that establish the boundary

Use disposable sentinels, never valuable files, as the protected targets:

1. Without confinement, deliberately show the same user/command can modify the
   sentinel through the offending path. Reset this disposable fixture.
2. With confinement, try relative and absolute writes, a scratch symlink into
   the protected tree, writes through a published executable link, link
   replacement, rename, chmod and new-file creation. Assert refusal and unchanged
   sentinel bytes/link target. Test the set, not just one happy-path file.
3. Prove private scratch/HOME writes succeed, concurrent runs have separate
   state, later runs cannot see prior scratch, and child exit codes propagate.
4. For the actual incident, retain a regression running the real adapter against
   a disposable project and independently inspect the protected original.

The shared repository's `./test` includes the Linux runner contract. Passing it
does not prove a consuming project's tests actually invoke the runner.

Source: [Bubblewrap's security model](https://github.com/containers/bubblewrap#sandbox-security)
states that the caller's arguments define the boundary. Review changes to those
arguments as changes to enforcement, not cosmetic command cleanup.
