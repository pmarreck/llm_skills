# Interop and packaging

## Pure effect programs

A pure request algebra can describe `Finished`, `Rejected` and a bounded byte
`Request` with a continuation. Deterministic and OS-backed interpreters then
service the same program. Keep arithmetic and domain admission in Bend; an
adapter supplies effects, marshals values and copies a completed prefix.
Continuation encoding can help composition satisfy the affine/termination
checker; it does not remove the need for bounded interpreter progress.

A resumable source cursor records actual consumption, not the requested number
of results. Rejection and nonlinear sampling consume variable amounts. O(1)
raw-byte seeking does not establish O(1) access to the Nth sampled value.

Use canonical data models for charts or other views. Bend computes support,
sample coordinates and heights; a renderer converts that model into Kitty,
Sixel or text and writes it. Test model fixtures independently from encoders.
The same separation works for shuffle index plans and weighted-choice decisions.

## Generated JavaScript needs one coherent module graph

`bend Model.bend -o model.mjs` emits an importable facade of non-IO definitions;
it is not an executable CLI that automatically runs IO `main`. The default
export supplies functions. Erased/type parameters may be absent at runtime.
Derive real signatures from the generated facade rather than copying source
arity into JS calls.

Constructors are JS objects with a `$` discriminator, but imported constructor
names can be qualified differently in separately emitted graphs. A `Rejected`
from one graph was mistaken for a byte request by an interpreter from another,
causing stack exhaustion. Compile one public facade that imports the needed
modules; construct and consume its values consistently. Factory/accessor
functions reduce host dependence on generated names. Test refused results too.
JS arrays can alias the caller's storage; pure Bend ownership does not make a
host-language copy for you.

## C emission is not a stable C ABI

`bend Native.bend -o native.c` produces compiler-owned runtime code and entry
segments. Do not assume source ADTs map to C structs or a source function's
signature survives lowering. In 2.0.37, sum arguments/results could be flattened
into multiple segments; returning a function could still be eta-expanded.
An apparent exported segment was not a safe general boxed call boundary.

For the studied implementation, an IO `main` delivered a fresh **boxed entry
closure** in one effect payload. The C adapter retrieved it through the pinned
runtime's ordinary closure application machinery. This was a private, version-
locked adapter, not upstream's promised FFI. Reinspect generated code and test
each representation if changing compiler/runtime versions.

Keep the public ABI caller-owned and stable independently: fixed-layout word
pairs, pointer-plus-length buffers, explicit capacities, status values and
source callback contracts. Decide mutation/error precedence. Reject invalid
inputs before source consumption and define what output/state survives a
later failure. Prepared opaque values need a clear ownership transfer; do not
prepare a value twice while marshalling it.

Preserve exact host representations too. JSON numbers and JS Number cannot
represent every U64; use checked limb pairs, strings or a host BigInt interface
as appropriate. That does not extend Bend Nat's own backend range. Text I/O
also does not establish arbitrary-byte preservation: test embedded zeros and
invalid UTF-8 through the actual byte-oriented adapter when those are in scope.

## Own the runtime lifetime

Embedding should not accidentally start the standalone event loop, install
process signal handlers, initialize GPUs or launch workers. Inspect generated
startup and reachability, initialize only the runtime machinery the adapter
needs, and hide compiler-private symbols from the public ABI.

A serialized evaluator needs a documented synchronization policy. Releasing
the evaluator mutex around a user callback enabled callback reentry in the
studied adapter; retained continuations had to remain owned while outside the
gate. Test nested callback success/failure and state advancement. A passing
single-thread reentry test is not multithread/fork/unload stress evidence.

The tested native embedding reserved an 8 GiB corpus plus 2 GiB evaluator
stack as virtual address space. This was an implementation configuration,
not a Bend requirement or resident-memory measurement. Track RSS separately.
Fixed-work heap high-water reuse is not a full live-allocation leak census.
Runtime exhaustion was fail-stop; zeroizing caller storage did not erase
temporary runtime heap copies. Do not advertise stronger allocation-failure
or secret-erasure guarantees without implementing and testing them.

## Build artifacts and Nix

Keep source SDK, generated JS SDK, static/shared C ABI and CLI separately
consumable. An installed-consumer test must compile/import using only the
installed SDK and load the standalone library without the CLI/toolchain.
Check runtime references, stripping, license notices and source fingerprints.
Generated runtime notices are part of redistribution, not optional examples.

Inspect the actual release binary's dynamic dependencies instead of inferring
them from the algorithm. The integer-only native example built with 2.0.37
still listed libm, libpthread and libc in its ELF dependencies. That does not
show that its integer algorithm uses floating point. The separately linked
embedding can have a different dependency set; neither result establishes
distribution portability on another host.

Bend resolves module paths canonically. In the tested Nix layout, directly
symlinking a store SDK into a consumer caused module-name validation failures.
Copy the installed module tree beside the consumer, then import it with a
normal relative path. Do not guess this from whether the filesystem symlink
is readable; execute an installed-only consumer.

The source tag's generated flake once selected a different release archive
than its own tag. Verify actual `bend version` and artifact digests. A narrow
documented archive override can repair a mismatch; do not silently upgrade the
project or search the Nix store for a usable compiler. Get paths from the
derivation, and put Git/reference compilers/kernel executables in every shell
or check that actually calls them.

Native host definitions are not execution evidence. The port executed on Linux
x86_64; aarch64 Linux/macOS definitions alone did not prove those runtime paths.
Windows, WASM and GPU support must be established separately. Keep host/target
and optimization-profile outputs separate; do not publish a foreign binary
under a host PATH name.
