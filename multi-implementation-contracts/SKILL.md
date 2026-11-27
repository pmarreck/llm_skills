---
name: multi-implementation-contracts
description: Maintain interchangeable implementations with shared acceptance tests and separately built consumers that exercise public ABIs. Use for cross-language implementation parity, CLI/ABI drift, or consumers bypassing exported interfaces; not merely because a project contains several languages.
---

# Multiple implementations and enforced public contracts

Keep the public contract usable by real consumers when implementation details
change or agent context is lost. The owner-observed failure is a CLI reaching
around an ABI into internal functions while CLI tests stay green. Prevent that
route through the build graph, rather than relying on reminders alone.

## Choose the smallest effective consumer boundary

For each maintained public ABI, build at least one acceptance consumer using
only the packaged interface and library artifacts. The consumer's source inputs
and dependency graph must exclude core implementation sources/modules. It must
not use a Rust core crate as a normal dependency, Zig-import the implementation,
or compile the core directly into its source graph as a shortcut. Linking the
exported library is expected; static linking does not defeat this boundary.

A CLI written in another language is a useful sustained consumer. For two
implementations, reciprocal consumers can work particularly well:

```text
Rust CLI -> public C ABI -> Zig core
Zig CLI  -> public C ABI -> Rust core
              both run the same CLI acceptance suite
```

Crossing languages makes accidental internal imports harder, but language alone
is not enforcement. A separately packaged same-language consumer that links
only the C ABI can establish the boundary too. Preserve an existing qualified
frontend where it already achieves this; do not rewrite every CLI solely to
make the diagram symmetric. Add a small external ABI consumer when that is
enough. Additional implementations need an explicit project purpose.

## Canonical implementation and build graph

Use the existing `CANONICAL_IMPL` mechanism. With interchangeable cores,
identifiers refer to the core/backend, while an explicit build mapping chooses
its CLI consumer. `zig` may therefore publish a Rust CLI over the Zig library.
Follow [canonical implementation selection](../cross-platform-project-build-arch/references/canonical-implementations.md)
for defaults, output namespaces, `./build` scope and safe publication. Preserve
the existing qualified default during a port. This skill does not authorize
changing the product default or adding another selection file.

Build libraries and external consumers as separate Nix derivations. Consumer
derivations receive the public headers/bindings and matching libraries, plus
their own sources and declared dependencies. Source filtering must actually
exclude core sources; putting code in a different directory alone is not a
barrier. Inspect package graphs and link commands to catch hidden core rebuilds
or undeclared native-module dependencies.

For Rust libraries consumed through a C ABI, use the appropriate `staticlib`
or `cdylib` artifact. A Rust `rlib` is not the public C ABI. Static libraries
can include additional symbols; do not mistake a symbol listing for proof that
consumers cannot bypass the interface. Restrict consumer dependencies and
review the declared exports for the chosen linking mode.

## One contract, separately invoked products

Define common acceptance cases independently of the implementations. Parameterize
the suite by an exact executable/library path; do not duplicate expectations
per language, run a stale PATH binary, or silently fall back to the canonical
implementation when another fails. Reach every required suite from `./test`.
Build prerequisites once through Nix; keep runtime cases small and isolated.

Declare the required frontend/core/platform combinations in existing build/test
metadata. Two crossed pairs are a useful minimum for reciprocal dogfooding;
when either frontend is intended to work with either core, test all four pairs.
Do not imply an untested combination or target is supported. Report native
execution separately from cross-compilation.

Common CLI acceptance should cover documented stdout/stderr, exit codes,
structured outputs and errors. Normalize only explicitly nondeterministic
fields; do not hide semantic differences with broad output filtering.
CLIs adapt arguments, files and presentation; core domain operations and policy
must remain behind the public interface rather than being reimplemented in the
frontend to compensate for a missing ABI operation.

## Prove that the boundary check can fail

- Build the consumer against the packaged library and public declarations in
  isolation, without the core source tree. Inspect actual compiler/link inputs.
- In a disposable negative fixture, remove or rename an export that the
  consumer requires: consumer compilation/linking must fail, or a runtime-loaded
  ABI must reject loading clearly. Never mutate live outputs or production
  libraries for this test. A missing source tree alone is not proof if the
  consumer quietly rebuilds another copy.
- Check the declared export inventory against the packaged ABI. Functions that
  the CLI never calls still need direct external ABI coverage. A parser or
  generator can make new public declarations visible to the gate; a producer's
  hand-maintained symbol list can omit the same function it forgot to test.
- Test pointer-plus-length binary data including embedded NULs, documented
  null/empty cases, buffer sizes, struct layout/alignment, error codes, callback
  lifetime, allocation/free pairing and concurrency where the contract exposes
  them. Use only contract-valid pointers; arbitrary invalid pointers need not be
  safely recoverable. Specify ownership and panic/unwind policy explicitly.
- Exercise any promised ABI-version compatibility using the appropriate frozen
  consumer fixtures. Rebuilding both sides together can conceal a compatibility
  break; backward compatibility is a separate promise from same-version parity.

## Keep the evidence independent

Identical results do not prove correctness when implementations share the same
mistake. Combine shared suites with published vectors, external oracles,
metamorphic properties and negative controls as appropriate. Cross-language
dogfooding validates a consumption path, not automatically every ABI operation,
security property or historical version. Apply [mfic](../mfic/SKILL.md) to those
claims and [test-isolation](../test-isolation/SKILL.md) to fixtures and outputs.

For a new ABI operation, acceptance means public declaration, implementation,
external-consumer use or direct ABI test, and a shared behavioral case. Update
the inventory and required matrix together. Keep internal unit tests too:
external acceptance tests protect the seam, while fast unit tests diagnose
core behavior without paying FFI/process startup on every case.

## Primary references

- [Rust artifact types and foreign linkage](https://doc.rust-lang.org/reference/linkage.html)
- [Rust FFI contracts](https://doc.rust-lang.org/nomicon/ffi.html)
- [Zig documentation; use the project's pinned version](https://ziglang.org/documentation/)
