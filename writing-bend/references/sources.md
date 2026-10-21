# Primary sources and version evidence

Reviewed 2026-10-21. The runnable examples target Bend **2.0.37**, pinned at
`4ff8545f19b09b7d2b8ca2303668100eac8efd66`. This is not a promise of compatibility
with a different release. The compiler advertised 2.0.38 as an available update
during this work; the project pin was deliberately left unchanged.

## Upstream navigation

- [Pinned official guide](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/guide/GUIDE.md): language, affine ownership, recursion, arrays, proofs, effects and command forms. Also available as `bend guide` from the installed compiler.
- [Current official repository](https://github.com/bendlang/bend): discovery and release changes; older Bend 1/HVM tutorials describe a different language.
- [Pinned agent guidance](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/AGENTS.md): source-file map and upstream contribution restrictions; it is guidance for that repository, not authority to edit a consumer's compiler.
- [Base](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/bend2/base.bend): actual quantity/type/effect signatures; inspect locally with `bend base NAME`.
- [Compiler and runtimes](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/bend2/comp.ts): backend representation, generated ABI and ownership details; no stable embedding ABI is inferred from its existence.
- [CLI](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/bend2/main.ts): option parsing, output selection and kernel discovery.
- [BendTT elaboration](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/bend2/safe.ts) and [Lean kernel](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/bend2/bendtt.lean): stronger verdict and its trust boundary.
- [BendTT paper](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/paper/BendTT.pdf) and [BendRT paper](https://github.com/bendlang/bend/blob/4ff8545f19b09b7d2b8ca2303668100eac8efd66/paper/BendRT.pdf): theory/runtime design, not performance evidence for an unmeasured application.

Do not copy upstream marketing statements about speed or "no mistakes" into a
client's verification claims. Read its limitations and identify the exact law,
input domain, backend, foreign operations and observed run behind each claim.
Neither updating a skill nor reading upstream docs authorizes upgrading the
compiler, publishing a BendHub package or modifying a project's reviewed laws.

## Example checks

Use a compatible project environment and run from this skill's directory.
Copy this skill's `examples/` beside a
consumer or use its physical path; avoid importing a store SDK through a
symlink whose canonical path has invalid module components. Use a private
writable RAM-backed work directory supplied by the caller for outputs.

```sh
bend version
bend examples/PROOF.bend
bend examples/Library.bend -o "$work/library.mjs"
node examples/check-sdk.mjs "$work/library.mjs"
bend examples/main.bend -o "$work/example"
"$work/example" --threads 1
```

The pure JS consumer checks little-endian content, limb carry/wrap and list
folding independently. The native entrypoint must print `8:0:10` with a newline.
The laws concern encoding length, one carry endpoint and empty-fold behavior;
they do not prove arbitrary word arithmetic or serialization content.

For a separate verdict receipt, provide a compatible prebuilt executable:

```sh
BENDTT="$kernel" bend examples/PROOF.bend --verdict
```

Check every status and the proof success marker. A local mutation removing an
encoded byte must fail the length law; mutate a private copy, not the live
example/specification. Shared skill installation tests establish discovery,
not Bend compiler/proof/runtime conformance.

## Verification receipt, 2026-10-21

With the pinned 2.0.37 compiler on Linux x86_64:

- The bundled laws passed the ordinary checker and the separately supplied
  BendTT verdict executable, both with status 0 and `ALL PROOFS CHECK`.
- Generated JS passed the independent little-endian, carry, wrap and fold
  assertions. The compiled native example printed exactly `8:0:10\n`.
- A fresh-context forward trial used this skill to implement a different,
  big-endian encoder, a length law, a coherent JS facade and native I/O.
  Both backends matched 16 boundary vectors from Node's `Buffer.writeUInt32BE`.
  A deliberately wrong four-zero encoder failed that content oracle, although
  a length-only law could accept it.
- Removing one byte in a private copy preserved model type-checking but made
  the unchanged length proof fail specifically with `SOME PROOFS FAIL`,
  status 1. A separate mutation of the law tripped its retained digest
  sentinel. These are test-control receipts, not proofs of byte content or a
  tamper-proof specification registry.

The shared skill repository's full suite also passed. It tests installation
and shared tooling; the compiler/backend checks above were separate explicit
runs. No GPU, Windows, WASM or additional compiler version was validated here.
