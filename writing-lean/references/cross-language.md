# Proving code written in other languages

Surveyed 2026-11-27 from the projects' repositories, papers and official
posts; none of these tools was run while writing this skill. Check the
project's current README and its pinned Lean toolchain before relying on one:
these tools trail Lean's monthly releases, and toolchain drift between them is
a reported pain point.

## Choose the guarantee first

There are three ways to connect Lean to code in another language. They give
different guarantees, and the claim matrix must say which one was used.

| Approach | What is proved | What remains trusted or tested |
|---|---|---|
| **Translate the code into Lean**, then prove things about the translation | Properties of a faithful model of the original source | The translator, the original language's compiler, and anything outside the supported subset |
| **Write the specification in Lean and test the implementation against it** (differential testing) | Properties of the Lean model only | Agreement between model and implementation is sampled evidence, not proof |
| **Write the implementation in Lean** and compile it, or link it through FFI | Properties of the code that actually runs | Lean's compiler, the runtime, the FFI boundary and every `@[extern]` or `@[implemented_by]` replacement |

An LLM that rewrites C or Python into Lean and proves the result has produced a
proof about its own rewrite. Treat the correspondence to the original as
untested until a differential gate covers it.

## Translators into Lean

| Project | Source | Supported subset | Status (2026-11) |
|---|---|---|---|
| [Aeneas](https://github.com/AeneasVerif/aeneas) with [Charon](https://github.com/AeneasVerif/charon) | Rust | Safe Rust only: no `unsafe` and no concurrency, and some loop and mutable-reference patterns are unsupported | Active, nightly releases, targets current Lean. Its README calls the Lean backend one of its two most mature. Charon describes itself as beta. |
| [hax](https://github.com/cryspen/hax) (`lean` backend) | Rust | Uses Charon and Aeneas, so it shares their subset | Lean backend under active development; F* is its stable backend. Lean support library: [hax-lean](https://github.com/cryspen/hax-lean). |
| [Clift](https://github.com/eisbaw/Clift) | C | Goes from clang's JSON AST through AutoCorres-style lifting stages | Work in progress by its own description. |
| [LNSym](https://github.com/leanprover/LNSym) | Armv8 (AArch64) machine code | ISA model plus a symbolic simulator | Active, Lean 4.35. Proofs about real machine code; conformance tests against hardware need an AArch64 host. |
| [Lean-MLIR](https://github.com/opencompl/lean-mlir) | MLIR / SSA IR | Semantics plus proofs that peephole rewrites preserve meaning | Research; pinned to an older nightly toolchain. |
| [EVMYulLean](https://github.com/NethermindEth/EVMYulLean) | EVM and Yul | An executable model, not a translator | Passes nearly all of the Ethereum Cancun conformance tests per Nethermind; work in progress. |

There is no mature, widely used translator from C++, Go, Python or WebAssembly
into Lean. Small or paper-only efforts exist. For those languages, use the
specification-plus-differential-testing pattern below.

Real use: Microsoft verifies Rust ML-KEM and SHA-3 in SymCrypt with Aeneas,
proving the Rust matches specifications derived from the standards
([announcement, 2026-07](https://microsoft.com/en-us/research/blog/verifying-rust-cryptography-in-symcrypt-from-standards-to-code)).
Microsoft says that code ships in Windows Insider builds.

## Specification in Lean, implementation elsewhere

AWS Cedar is the reference case
([paper](https://arxiv.org/abs/2407.01688),
[repository](https://github.com/cedar-policy/cedar-spec)). The authorization
engine is written in Rust; an executable Lean model carries the proofs; and
differential random testing compares the two on generated inputs. The paper
reports 21 bugs found by differential and property-based testing. The proofs
cover the model; the Rust is covered by testing. Report it that way.

This pattern fits this fleet's multi-implementation projects: the Lean model is
the proved oracle, and the shared external vectors and differential gates
connect it to the production implementations.

## From Lean to running code

- Lean compiles to C and native code. The new code generator was completed in
  Lean 4.30. The compiler is not verified, so it belongs in the trusted base.
- [SampCert](https://github.com/leanprover/SampCert) proves differential-privacy
  samplers in Lean and extracts them. Its README says they are deployed in the
  AWS Clean Rooms Differential Privacy service.
- No tool that extracts Lean to Rust or another language was found.

## AI provers and benchmarks

AI provers can close proof obligations while the Lean kernel checks every
step, so they cannot introduce unsoundness; they can only fail to find a
proof. The statement still needs human review. The benchmarks
[VERINA](https://github.com/sunblaze-ucb/verina) and
[CLEVER](https://github.com/trishullab/clever) measure end-to-end
specification, code and proof generation; reported 2025 proof success was
low (single-digit percentages). Do not plan around an agent proving a large
translated program unaided.
