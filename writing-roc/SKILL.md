---
name: writing-roc
description: Write, test, review or debug Roc language code using the project's actual compiler and platform versions. Provides current syntax, old-compiler traps and pure-core/platform-boundary guidance. Use for Roc source or Roc platform work, not merely for invoking an existing Roc executable.
---

# Writing Roc

An agent quick reference for the new Zig-based Roc compiler. Roc is still
pre-0.1; old Rust-compiler tutorials often describe incompatible syntax.

## Establish the dialect first

Read the project's intent, toolchain pin, app/package header and platform
sources. Run the project-provided `roc version` and consult its `--help`.
Use its Nix development environment when present; do not silently upgrade the
compiler or platform to make an example compile.

This reference was researched on **2026-10-04**, against official upstream
revision `1a4df199210309bbb6befb1322f7435361bd01e1`. It describes that compiler
generation, not a released stability guarantee. For an older project, follow
its actual dialect and identify the differences before changing source.

Read [syntax.md](references/syntax.md) when writing Roc expressions, types,
error handling or tests. Read [modules.md](references/modules.md) for imports,
public APIs, platform boundaries or dependency/version diagnosis.

## Architecture that fits functional projects

Keep domain transformations pure. Pass clocks, deterministic RNG state and
external results as values; keep I/O in effectful boundary functions. This fits
a functional core with dependency-injected adapters. Roc's platform owns I/O
primitives and the host ABI; do not invent a standard-library file API or assume
an arbitrary C FFI is callable from app code.

`->` marks a pure function type; `=>` marks an effectful one. Name effectful
functions with `!`. Purity does not prove termination or prevent `crash`,
allocation failure or diagnostic `dbg`/`expect`. A deterministic algorithm
implemented in Roc still needs behavioral tests or a separate proof.

Use immutable values by default. Local `var $name` state is available for loops
and does not automatically make a function effectful. Match known error cases
explicitly; report failures with `Try` and tags rather than `crash`.

Sources: [functions](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/functions.md),
[platforms](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/platforms.md).

## Verify with the actual compiler

Prefer the project's complete `./test` entry point. Typical underlying checks
for this generation are:

```sh
roc version
roc check main.roc
roc test main.roc
roc fmt --check .
```

Check every exit status. The compiler can continue running code with errors;
printed results do not establish a passing build. Warnings may also produce a
nonzero status. Keep check/test failures visible to the complete test runner.

Top-level `expect`s run with `roc test`. Expectations inside executed functions
are developer checks and may be omitted in optimized execution. Never implement
license, security or input-validation enforcement with `expect`.

The runnable [example](examples/main.roc) and its [type module](examples/Label.roc)
exercise the quick reference without downloading a platform. Run check/test on
`examples/main.roc` using the project's compatible compiler, then formatting
checks on `examples`. This example uses the built-in Echo platform; real app
entrypoint types come from the selected platform.

Example evidence: check, tests, run and formatting must be recorded separately
from source review. [syntax.md](references/syntax.md#verification-evidence)
records the observed compiler and limits. Shared skill installation tests do
not establish Roc compiler conformance.

## Keep this reference useful

If a repeated issue exposes a missing or misleading Roc rule, an agent may
make a small update to this shared skill. First reproduce or verify it against
the affected compiler/platform, include a source or regression example and
label version-specific behavior. Prefer correcting existing text over adding
another rule. Routine mistakes and one-off project quirks need no skill edit;
this is permission to learn from recurrence, not a required maintenance step.

Latest documentation: [official language reference](https://www.roc-lang.org/docs/main/langref/)
and [new-compiler tutorial](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/mini-tutorial-new-compiler.md).
Check these again when the project changes compiler generation.
