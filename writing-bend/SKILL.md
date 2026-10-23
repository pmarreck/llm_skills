---
name: writing-bend
description: Write, test, prove, package or review Bend 2 code using the project's actual compiler. Covers affine types, structural recursion, exact arithmetic, generated JavaScript and native embedding. Use for Bend source and runtime work, not merely invoking an existing Bend executable.
---

# Writing Bend

Use the installed compiler's language, not remembered Bend 1/HVM syntax.
This skill records experience with **Bend 2.0.37**, upstream revision
`4ff8545f19b09b7d2b8ca2303668100eac8efd66`, checked on 2026-10-21.
Newer documentation is a discovery aid, not evidence that a pinned project
supports a feature. These lessons are not a claim that every Bend release has
the same representation, ABI or limitations.

## Establish the toolchain

Read project intent, the compiler pin and existing build/test scripts. Obtain
the compiler through the project environment; run `bend version`, `bend --help`,
`bend guide` and the relevant `bend base NAME`. Check command exit statuses.
Do not run a network installer or `bend update` to make an example work.
Build project artifacts through `nix build`, invoking Bend/backend compilation
inside derivations. Follow `cross-platform-project-build-arch`; the pinned
devShell supports inspection/debugging, not an optional direct-build backend.
Do not patch the compiler, weaken laws, add unsafe recursion or reduce a
required test matrix to get a port through.

Route detail by the actual task:

- [Language and exact arithmetic](references/language.md) for syntax, ownership,
  recursion, numeric domains, arrays and large lookup tables.
- [Proofs and verification](references/proofs.md) for laws, the separate verdict
  kernel, mutation controls and the boundary of a correctness claim.
- [Interop and packaging](references/interop.md) for pure effect programs,
  generated-JS identity, native C embedding and Nix artifacts.
- [Measured implementation lessons](references/measurements.md) when choosing
  an algorithm, interpreting performance or diagnosing statistical parity.
- [Primary sources and version evidence](references/sources.md) when checking
  upstream behavior or changing a compiler pin.

## Pure core and explicit foreign boundaries

For an independent Bend implementation, represent state transitions,
validation, arithmetic, sampling and canonical
output models as pure Bend functions. Return explicit errors and state after
the last completed effect. An I/O edge can parse argv, obtain entropy, service
byte requests, render a canonical model to terminal protocols and write buffers.
Calling another language's numerical implementation from a host wrapper is
not an independent Bend implementation.

An intentional mixed-language application can instead use Zig hot kernels.
Keep that boundary explicit and use the
[hybrid workflow](references/measurements.md#a-bend-specification-with-zig-kernels)
to distinguish Bend model proofs from evidence about the foreign implementation.

Choose reusable data deliberately. `is Data` permits copying; `is Type` retains
affine ownership. A closure cannot be reused merely because its captures are
copyable. Mark reusable binders with `+` only when their types permit it; erased
`-` parameters do not carry runtime data. Explicit ownership often reveals an
architectural mismatch that extra annotations cannot repair.

## Verify separate boundaries

Use independent expected results, then compare the pure implementation,
generated JS, native core and public CLI/FFI as applicable. Exact numerical
ports need exact intermediates, error precedence, state/cursor consumption,
failure prefixes and boundary cases, not just close-looking decimal output.
Use the existing shared CLI suite without reducing another backend's matrix.

Compilation, ordinary proof checking, kernel verdict, runtime tests and
statistical evidence are different receipts. State which were actually run.
Backend execution and foreign/runtime code remain separate trust boundaries.
Never describe a few layout or endpoint laws as a proof of the whole algorithm.

The [examples](examples/Model.bend) include a pure limb model, separate
[laws](examples/LAWS.bend), [proofs](examples/PROOF.bend), a
[native I/O entrypoint](examples/main.bend) and an independent
[JS consumer](examples/check-sdk.mjs). The reproduction commands and their
measured verification scope are in [sources.md](references/sources.md#example-checks).

## Updating this skill

Keep verified lessons, sources and compiler versions together. Reproduce a
new trap before generalizing it. Correct an obsolete version-specific rule
instead of accumulating incompatible prescriptions. Keep large source/runtime
copies out of the skill; link official sources and retain small tested examples.
