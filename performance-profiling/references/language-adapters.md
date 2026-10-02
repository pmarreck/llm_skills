# Language adapters

The engine consumes a CLI's `performance-measurement/v1` JSON, not its human
benchmark output. See the tool's protocol and working pilot before creating an
adapter. Keep the kernel independent of storage/history policy. Use proper JSON
serialization, and return nonzero on invalid work, clock failure or crash.

## Zig and C

Create a dedicated optimized benchmark executable from the project's build graph.
Use `std.time.Timer` for monotonic wall intervals and a checked process/thread CPU
clock adaptor for the target OS. Propagate clock errors; returning zero hides a
broken measurement. Consume results with `std.mem.doNotOptimizeAway` plus an
independent correctness check. Choose enough batched work for clock resolution.

Prepare fixtures/warm up before measurement. Pass explicit sizes/iterations/seed;
emit every raw sample and adjacent-size input. Do not skip a required benchmark
when ordinary tests build Debug: run the optimized artifact separately from the
full `./test`. Keep safety-enabled unit/integration checks too. Nix checks can
build/test deterministic contracts; fresh historical timing belongs outside them.

Wrap allocator interfaces appropriate to the pinned Zig version; track actual
requested sizes and ownership through alloc/resize/free, including error paths.
`std.testing.allocator` checks ownership but does not automatically provide every
growth metric. Native C FFI allocations need instrumentation of their own.
Use pointer-plus-byte-length inputs for binary buffers; sentinel strings apply
only to APIs that actually require them. Coverage is part of the result.

Use the current project toolchain and writing-zig guidance instead of copying
old std.io/file-writer examples across Zig releases. Let the reusable engine own
statistical comparison and NDJSON writes; no per-library clone of that logic.

## LuaJIT

Provide LuaJIT, cjson and luv through the project flake. Warm up the actual JIT
paths in-process. `uv.hrtime()` is monotonic; `os.clock()` provides process CPU
time with platform-dependent resolution, so batch adequate work. Keep conversions
of high-resolution counters within exact numeric range.

Use recording allocation wrappers around malloc/free for selected FFI buffers,
or a suitable whole-runtime adapter. Lua GC and native allocations have different
lifetimes. State what's excluded and collect residuals after the intended cleanup
boundary. Never call a tracked input vector's peak the entire program's peak.

Existing battle-tested dotfiles/project tooling may provide fixtures or RNGs.
Use the `random` project's seeded generator for randomized workload data rather
than invent another algorithm. The engine's fresh run IDs do not define a
benchmark's deterministic fixture algorithm.
