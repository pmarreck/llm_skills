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

## Tier 1: Microbenchmarks (in the test suite)

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
```
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
```

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

| Change | Action |
|---|---|
| > +15% slower | **FAIL** -- `return error.PerformanceRegression`. Investigate before shipping. |
| > -15% faster | **FLAG** -- print improvement notice. Verify it's real, not noise. |
| Within +/-15% | Normal variance. Log and continue. |

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
  bench.zig              # Full benchmark suite binary
  bench_results.jsonl    # Suite history (git-tracked)
  micro_results.jsonl    # Microbenchmark history (git-tracked)
```

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
```
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
