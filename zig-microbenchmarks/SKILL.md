---
name: zig-microbenchmarks
description: Use when adding benchmarks to a Zig project, tracking hot path performance, investigating regressions, or setting up benchmark infrastructure.
---

# Zig Microbenchmarks

## Overview

Two tiers of benchmarking, both first-class citizens:

1. **Microbenchmarks** -- fast, run as part of `zig build test`, **fail the test suite** if performance drifts outside a +/-15% window from the last recorded baseline. These are the performance equivalent of unit tests.
2. **Benchmark suite** -- longer, thorough, run via `zig build bench`. For deep investigation, profiling, and before/after comparisons on real-world data.

Both log results to JSONL (git-tracked) for historical tracking.

<important>
Core principle: If a function is hot enough to optimize, it's hot enough to benchmark. If it regresses, the test suite should scream.
</important>

<when_to_use>

- Adding or modifying a hot-path function
- Setting up benchmark infrastructure for a new Zig project
- Performance regression detected via end-to-end testing and you need to isolate which function regressed
- User says "benchmark", "perf", "regression", "throughput", or "ns/op"
  </when_to_use>

## Key Rules

<important>
1. **Always use `std.time.Timer`** (monotonic), never `nanoTimestamp()` (wall clock).
2. **Always use `std.mem.doNotOptimizeAway`** on results to prevent dead-code elimination.
3. **Log results to JSONL** (append mode) for historical tracking. JSONL files are git-tracked.
4. **Warm up before measuring** -- first iterations may be cold-cache outliers.
</important>

## Tier 0: The scaling-ratio gate (PRIMARY — catches complexity regressions)

This is the _hard_ gate, and it should exist for every hot path as soon as it hits
MVP. A single-point time microbench (Tier 1 below) measures _magnitude_ and is noisy
and machine-dependent; an accidental `O(m×n)` loop with a small constant sails right
through it at one input size. The scaling gate measures **growth shape**, which is the
thing that actually broke — and because it compares a function to _itself_ at growing
N, the **ratio cancels machine speed: it needs no per-machine baseline and holds
identically in CI on any box.** It's an MFIC metamorphic test (oracle-free): you assert
a _relationship_ f(2N)≈k·f(N), not a logged number.

### Step 1 — declare intended complexity on each hot function

```zig
// complexity: O(n)   -- candidate scan: one pass over the text
fn referenceScan(...) ... { ... }
```

The annotation is the producer's falsifiable claim; the gate is its independent check.
An agent who writes a quadratic loop under `// complexity: O(n)` fails the build.

### Step 2 — the harness (`tests/scaling.zig`, ReleaseFast only)

```zig
const std = @import("std");

/// CPU/user time, not wall-clock: excludes time the process was scheduled out, so it
/// is far steadier on a loaded machine (a fleet, a laptop). Single-threaded kernels
/// only; use wall-clock for parallel/I-O work. POSIX shown; Windows: GetProcessTimes.
fn cpuTimeNs() u64 {
    var ts: std.posix.timespec = undefined;
    std.posix.clock_gettime(.PROCESS_CPUTIME_ID, &ts) catch return 0;
    return @as(u64, @intCast(ts.sec)) * 1_000_000_000 + @as(u64, @intCast(ts.nsec));
}

/// Median per-doubling growth ratio of `work` at N, 2N, 4N, 8N.
/// min-of-K per size suppresses noise; median-of-ratios is robust to one bad point.
fn growthRatio(work: *const fn (usize) void, base: usize) f64 {
    const sizes = [_]usize{ base, base * 2, base * 4, base * 8 };
    var t: [4]u64 = undefined;
    for (sizes, 0..) |n, i| {
        var best: u64 = std.math.maxInt(u64);
        var k: usize = 0;
        while (k < 5) : (k += 1) {
            const s = cpuTimeNs();
            work(n);
            const d = cpuTimeNs() - s;
            if (d < best) best = d;
        }
        t[i] = best;
    }
    var r = [_]f64{
        @as(f64, @floatFromInt(t[1])) / @as(f64, @floatFromInt(t[0])),
        @as(f64, @floatFromInt(t[2])) / @as(f64, @floatFromInt(t[1])),
        @as(f64, @floatFromInt(t[3])) / @as(f64, @floatFromInt(t[2])),
    };
    std.mem.sort(f64, &r, {}, std.sort.asc(f64));
    return r[1]; // median
}

test "scaling: referenceScan stays linear" {
    // Pick `base` large enough that the linear term dominates constant factors.
    const ratio = growthRatio(benchReferenceScan, 8192);
    // linear ≈ 2.0, n·log n ≈ 2.2, quadratic ≈ 4.0. Gate at 2.8: catches the
    // quadratic class with headroom for noise + log factors.
    if (ratio >= 2.8) {
        std.debug.print("referenceScan growth {d:.2}× per doubling — super-linear!\n", .{ratio});
        return error.ComplexityRegression;
    }
}
```

### Rules

- **Threshold 2.8×** for an `O(n)`/`O(n log n)` declaration. For an intentionally
  `O(n²)` kernel, gate at ~5× (still catches a slip to cubic). Match the gate to the
  _declared_ complexity, not a universal constant.
- **Verify the gate bites:** confirm it FAILS on the pre-fix (quadratic) code and
  PASSES fixed — that's the TDD reproduce-then-guard loop; a gate never seen red is
  vacuous (MFIC: the F).
- **Honest residuals:** if a rare/secondary path is still super-linear but you're not
  fixing it now, make the gate **report-only** for that phase and track it — do NOT
  let it gate green falsely (same discipline as a fence ledger).
- **Wire it in:** `./bm` runs it locally; add a flake `checks.scaling` so Garnix runs
  it in-sandbox (the ratio is machine-independent, so it passes there with no baseline).

Microbenchmarks live alongside unit tests in `src/lib.zig` (or wherever tests live). They are fast (target <500ms each), run on every `zig build test`, and **fail** if performance drifts outside the window.

### The challenge: test runner runs Debug

Zig's test runner defaults to Debug optimization, which makes timing meaningless. Two approaches:

**Approach A: Guard with `@import("builtin").mode`** (recommended)

<template>
```zig
const builtin = @import("builtin");

test "microbench: hot_function throughput" {
// Skip in Debug -- timings are meaningless
if (builtin.mode == .Debug) return;

    const input = generateTestInput(4096);
    const log_path = "bench/micro_results.jsonl";

    // Warm up
    for (0..100) |_| {
        const r = hotFunction(input);
        std.mem.doNotOptimizeAway(r);
    }

    // Measure
    const iterations: u64 = 10_000;
    var timer = try std.time.Timer.start();
    _ = timer.lap();
    for (0..iterations) |_| {
        const r = hotFunction(input);
        std.mem.doNotOptimizeAway(r);
    }
    const elapsed_ns = timer.read();
    const ns_per_op = elapsed_ns / iterations;

    // Log result
    const result = MicroBenchResult{
        .name = "hot_function_4k",
        .ns_per_op = ns_per_op,
        .timestamp = std.time.timestamp(),
    };
    try appendJsonl(log_path, result);

    // Check against baseline (last entry in JSONL for this name)
    const baseline = try loadBaseline(log_path, "hot_function_4k", std.testing.allocator);
    if (baseline) |base_ns| {
        const ratio = @as(f64, @floatFromInt(ns_per_op)) /
            @as(f64, @floatFromInt(base_ns));
        if (ratio > 1.15) {
            std.debug.print(
                "\n*** PERF REGRESSION: {s} -- {d} ns/op vs baseline {d} ns/op (+{d:.1}%) ***\n",
                .{ "hot_function_4k", ns_per_op, base_ns, (ratio - 1.0) * 100.0 },
            );
            return error.PerformanceRegression;
        }
        if (ratio < 0.85) {
            std.debug.print(
                "\n>>> PERF IMPROVEMENT: {s} -- {d} ns/op vs baseline {d} ns/op ({d:.1}%) <<<\n",
                .{ "hot_function_4k", ns_per_op, base_ns, (ratio - 1.0) * 100.0 },
            );
        }
    }

}

````
</template>

To actually run microbenchmarks, use `zig build test -Doptimize=ReleaseFast`. In the build.zig test step, consider adding an option:

```zig
// build.zig: allow optimized test runs for microbenchmarks
const test_optimize = b.option(
    std.builtin.OptimizeMode,
    "test-optimize",
    "Optimization for tests (default: Debug; use ReleaseFast for microbenchmarks)",
) orelse .Debug;

const unit_tests = b.addTest(.{
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = test_optimize,
    }),
});
````

Then: `zig build test -Dtest-optimize=ReleaseFast` runs microbenchmarks.
Plain `zig build test` skips them (Debug mode, guard returns early).

**Approach B: Separate microbench test step** in build.zig:

<template>
```zig
// Microbenchmark tests -- always ReleaseFast
const micro_tests = b.addTest(.{
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = .ReleaseFast,
        .single_threaded = true,  // reduce timing noise
    }),
});
micro_tests.filters = &.{"microbench:"};
b.step("microbench", "Run microbenchmarks (ReleaseFast)")
    .dependOn(&b.addRunArtifact(micro_tests).step);
```
</template>

Then: `zig build microbench` runs only tests prefixed with `"microbench:"`.

### Microbenchmark naming convention

Prefix all microbenchmark test names with `microbench:` to allow filtering:

<example>
```zig
test "microbench: lzma2_encode_block_4k" { ... }
test "microbench: match_finder_bt4_lookup" { ... }
test "microbench: crc32_8k" { ... }
```
</example>

### Window: +/-15%

This Tier-1 single-point window is the **secondary, constant-factor gate** — it catches
"this got slower at a fixed size" (a cache-hostile access pattern, an extra allocation)
that the Tier-0 scaling gate, which only watches growth _shape_, can miss. Run it on the
same **CPU/user time** basis as Tier 0 (steadier than wall-clock). Tolerance is
metric-dependent: ~10% on deterministic op/alloc counts, the ~15–25% here on noisy time
(or use min-of-N). Both directions matter — a surprise speedup may mean a skipped path.

| Change        | Action                                                                         |
| ------------- | ------------------------------------------------------------------------------ |
| > +15% slower | **FAIL** -- `return error.PerformanceRegression`. Investigate before shipping. |
| > -15% faster | **FLAG** -- print improvement notice. Verify it's real, not noise.             |
| Within +/-15% | Normal variance. Log and continue.                                             |

<remember>
Rerunning is implicit acceptance -- the new result becomes part of the rolling baseline.
</remember>

## Tier 2: Benchmark Suite (separate binary)

The full benchmark suite is for deeper investigation: varying input sizes, comparing algorithms, profiling. It's a separate executable.

### build.zig addition

<template>
```zig
const bench_mod = b.createModule(.{
    .root_source_file = b.path("bench/bench.zig"),
    .target = target,
    .optimize = .ReleaseFast,
});
bench_mod.addImport("project_name", core_mod);

const bench_exe = b.addExecutable(.{
.name = "bench",
.root_module = bench_mod,
});
const run_bench = b.addRunArtifact(bench_exe);
if (b.args) |args| run_bench.addArgs(args);
b.step("bench", "Run full benchmark suite").dependOn(&run_bench.step);

```
</template>

Usage: `zig build bench` or `nix develop -c zig build bench`

### Directory structure

```

bench/
bench.zig # Full benchmark suite binary
bench_results.jsonl # Suite history (git-tracked)
micro_results.jsonl # Microbenchmark history (git-tracked)

````

### Suite harness pattern

<template>
```zig
const std = @import("std");
const Timer = std.time.Timer;
const lib = @import("project_name");

const BenchResult = struct {
    name: []const u8,
    iterations: u64,
    ns_per_op: u64,
    throughput_mb_s: ?f64,
    timestamp: i64,
};

fn runBench(
    name: []const u8,
    iterations: u64,
    input_bytes: ?u64,
    func: *const fn () void,
) BenchResult {
    // Warm up (10% of iterations, minimum 10)
    const warmup = @max(iterations / 10, 10);
    for (0..warmup) |_| func();

    var timer = Timer.start() catch @panic("Timer.start failed");
    _ = timer.lap();
    for (0..iterations) |_| func();
    const elapsed_ns = timer.read();

    const ns_per_op = elapsed_ns / iterations;
    const throughput: ?f64 = if (input_bytes) |bytes|
        @as(f64, @floatFromInt(bytes * iterations)) /
            (@as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s) /
            (1024.0 * 1024.0)
    else
        null;

    return .{
        .name = name,
        .iterations = iterations,
        .ns_per_op = ns_per_op,
        .throughput_mb_s = throughput,
        .timestamp = std.time.timestamp(),
    };
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    // ... run benchmarks, log to bench_results.jsonl, report ...
    // See Tier 1 for JSONL logging and baseline comparison patterns.
    // Suite uses same thresholds but prints warnings rather than failing.
}
````

</template>

## JSONL Format and History

Both tiers log to JSONL (one JSON object per line, append mode, git-tracked):

```json
{"name":"hot_function_4k","ns_per_op":4523,"timestamp":1743552000}
{"name":"hot_function_4k","ns_per_op":4491,"timestamp":1743638400}
```

### Shared helpers (put in a common module)

<template>
```zig
const MicroBenchResult = struct {
    name: []const u8,
    ns_per_op: u64,
    timestamp: i64,
    throughput_mb_s: ?f64 = null,
    iterations: ?u64 = null,
};

fn appendJsonl(path: []const u8, result: MicroBenchResult) !void {
const file = std.fs.cwd().openFile(path, .{ .mode = .read_write }) catch |err| switch (err) {
error.FileNotFound => try std.fs.cwd().createFile(path, .{}),
else => return err,
};
defer file.close();
try file.seekFromEnd(0);
try std.json.stringify(result, .{}, file.writer());
try file.writer().writeByte('\n');
}

fn loadBaseline(
path: []const u8,
name: []const u8,
allocator: std.mem.Allocator,
) !?u64 {
const file = std.fs.cwd().openFile(path, .{}) catch return null;
defer file.close();
var last_values: [5]u64 = undefined;
var count: usize = 0;
var buf: [4096]u8 = undefined;
const reader = file.reader();
while (reader.readUntilDelimiterOrEof(&buf, '\n') catch null) |line| {
const parsed = std.json.parseFromSlice(
MicroBenchResult, allocator, line,
.{ .ignore_unknown_fields = true },
) catch continue;
defer parsed.deinit();
if (std.mem.eql(u8, parsed.value.name, name)) {
last_values[count % 5] = parsed.value.ns_per_op;
count += 1;
}
}
if (count == 0) return null;
const n = @min(count, 5);
var slice = last_values[0..n];
std.mem.sort(u64, slice, {}, std.sort.asc(u64));
return slice[n / 2];
}

```
</template>

## What to Benchmark

Target the **hot path** -- functions called once per file or once per block in a loop:

| Project Type | Microbench These |
|---|---|
| Compression (z7z, bzip2z, zstdz) | encode/decode per block, match finder, entropy coder |
| Validation (validate) | per-format validator on representative input |
| Archival (BLIP) | container expansion/contraction per format |
| Scanning (entropy_shield) | per-file scan, batch scan throughput |
| Text search (codescan, chatscan) | index lookup, search query |

## Common Mistakes

<important>
- **Benchmarking in Debug mode** -- results are meaningless. Always guard or use a separate ReleaseFast step.
- **Forgetting `doNotOptimizeAway`** -- compiler eliminates dead computation, benchmark shows 0 ns.
- **Too few iterations** -- Timer resolution is ~1ns but system noise is ~100ns. Target >100ms total.
- **Not warming up** -- first iterations trigger page faults, cache fills. Discard warmup.
- **Not tracking history** -- a benchmark without history is just a number. Log to JSONL, commit it.
- **Running microbenchmarks in CI** -- CI hardware varies. Microbenchmarks should run locally. CI can verify they compile.
</important>
```
