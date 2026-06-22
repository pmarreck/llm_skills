---
name: deep-code-review
description: Use when auditing a codebase or major subsystem for quality and missed issues. Triggers - "review the codebase", "audit", "what did I miss", or at project milestones.
---

# Deep Code Review

## Overview

A comprehensive codebase-wide review across 11 dimensions, executed via parallel subagents. This is not a diff/PR review -- it's a full audit of the current state of the code.

<important>
Output goes to a file (`CODE_REVIEW.md` in the project root), not inline.
</important>

<when_to_use>

- User says "review the codebase", "audit", "code review", "what did I miss"
- A major milestone or feature is complete and needs a quality pass
- Before a release or public announcement
- Periodically as a health check
  </when_to_use>

## Workflow

### Step 1: Orient

Before dispatching subagents, understand the project:

```bash
dirtree                          # project file layout and file descriptions
codescan status                  # is index current and indexer running?
```

Read `CODE_MINIMAP.md` if it exists, otherwise the notes added by `dirtree` on the project dir files. Read `PLAN.md` to understand what's been done and what's in progress. Identify the primary language(s).

### Step 2: Dispatch 11 Parallel Subagents

Launch one subagent per review dimension. Each subagent should:

- Use `codescan search`, `codescan symbols`, `dirtree`, and file reads
- Report findings with **severity** (CRITICAL 🔥, WARNING ‼️ or ADVISORY ⚠️) and **file:line** references
- Be language-aware (Zig, C, Nix, or whatever the project uses)

<important>
Give each subagent the project path, the primary language, and a clear scope. Tell them to write their findings to a temp file. Collect and merge results after all complete.
</important>

### Step 3: Compile Results

Merge all subagent findings into `CODE_REVIEW.md` with sections per dimension, sorted by severity within each section.

---

## The 11 Review Dimensions

### 1. Inconsistent, Incomplete, or Undefined Functionality

Principle: We want clear and concise code.

Look for:

- Functions that are declared or stubbed but not implemented (`TODO`, `unimplemented`, empty bodies, returning immediately)
- Features mentioned in PLAN.md or CLAUDE.md that aren't reflected in code
- Inconsistent behavior between similar code paths (e.g., one validator checks X but another doesn't)
- API surface that promises something the implementation doesn't deliver

### 2. Inadequate Test Coverage

Principle: We want to test every possible input value within a reasonable set of inputs across both success and failure code paths.

Look for:

- Functions with no corresponding test when a test is reasonable
- Mapping/lookup functions whose tests don't check every possible input value within a finite and reasonably small set of inputs (examples: a byte mapper, language translations)
- Missing boundary conditions: empty input, max-size input, off-by-one, null/zero, unicode, negative values
- Missing error path testing (does the test suite exercise error branches?)
- Code paths only tested with happy-path data
- **[Zig]** `catch unreachable` in production code that hasn't been tested with the error condition

### 3. Futile Test Coverage

Principle: We want meaningful tests.

Look for:

- Assertions that test trivially true conditions (`expect(true)`, `expect(1 == 1)`)
- Tests that only verify the test setup, not actual behavior
- Tests that can never fail because they test implementation details that are tautologically correct
- Tests whose assertions don't actually constrain the behavior they claim to test
- Snapshot tests that were auto-accepted without review

### 4. Fast test coverage

Principle: We want the main test suite to be as fast as possible without sacrificing correctness. Fast tests mean quicker iteration.

Look for:

- Sleeps, or other subpar impure non-deterministic patterns in tests or code that can almost always be done in a more deterministic, pure way (such as callbacks, injecting the current time, etc.)
- Loops of hundreds or thousands of iterations that could be proven with fewer (unless statistical significance is being measured)
- Driving a headless browser- notoriously bad for test performance and should be avoided as much as possible, but is sometimes necessary for testing browser-specific behavior- consider a separate integration or QA style test suite for this, and mandate it runs before deploys or commits
- Not using any provided regression test selection via dependency graph analysis feature that the language or ecosystem might provide (example: `mix test --stale`) in the default acceptance unit test (which I usually have wired to ./test in the project root)

### 5. Superfluous or Duplicated Functionality

Principle: Every LOC has an ongoing maintenance cost.

Look for:

- Two functions that do the same thing with slightly different signatures
- Copy-pasted logic that should be factored out (3+ similar blocks)
- Dead code: functions defined but never called, unreachable branches, commented-out code left behind
- Unused imports, unused variables, unused struct fields
- Wrapper functions that add no value over calling the inner function directly

### 6. Suboptimal, Inconcise, or Disorganized Code

Principle: We want clearly-written, low-maintenance code that is easy to understand and maintain by either agents or humans.

Look for:

- Overly verbose code that could be expressed more clearly
- Deeply nested conditionals that could be flattened (early returns, guard clauses)
- Poor naming: single-letter variables in non-trivial scope, misleading names, inconsistent conventions
- Files that mix unrelated concerns; functions in the wrong file
- Dense regexes that are not in the extended, indented, commented form in languages where that option is available
- Functions that are too long (>100 lines) and should be decomposed (high cyclomatic complexity)
- Magic numbers without named constants

### 7. Algorithmic Complexity

Principle: We want maximally-efficient algorithms that scale well with input size, because not doing so costs unnecessary energy and time.

Look for:

- Inner loops that are O(n^2) when O(n log n) or O(n) is achievable (especially: nested linear scans over collections, repeated string concatenation)
- Repeated work inside loops that could be hoisted (precomputation, memoization, lookup tables)
- Unnecessary allocations in hot loops -- estimate ops/iteration
- **[Zig]** Using `page_allocator` directly instead of arena/GPA, large stack buffers that should be heap-allocated
- Consider (in languages with integrated GC) how hard the GC will have to work to keep up with the program's allocations; refactor if an improvement is possible
- Estimate the Big-O of the program's hot loops and flag anything worse than necessary
- Consider annotating hot-loop functions with their _expected_ Big-O complexity
- Hot loops should have their time complexity checked within a microbenchmark that is part of the main test suite (for Zig specifically, try the zig-microbenchmarks skill)

### 8. Files Without Clear Purpose

Principle: Every LOC and file has an ongoing maintenance cost; thus, they should have a clear purpose

Look for:

- Files that are suspiciously small (<10 lines) or suspiciously large (>1000 lines)
- Files whose name doesn't match their content
- Utility/helper files that have become grab-bags of unrelated functions
- Files that exist only because of a refactor or other work that was never completed
- Orphaned test files that test modules that no longer exist
- Use `dirtree` for the overview and `codescan symbols --file <path>` to inspect suspicious files

### 9. Not Leveraging Language Features

Principle: Languages have unique and sometimes recent features that provide advantages at either compile or runtime and should thus be leveraged.

**[Zig-specific]:**

- Not using `comptime` where compile-time evaluation would eliminate runtime cost
- Not using tagged unions where if/else chains on type tags exist
- Not using `errdefer` for cleanup on error paths
- Using manual loops instead of `std.mem` / `std.sort` / `std.fmt` builtins
- Not using sentinel-terminated types at FFI boundaries
- `@as` casts that could be replaced with `@intFromFloat` / `@floatFromInt` etc.
- Manual bit manipulation instead of `std.PackedIntArray` or `std.bit_set`

**[C-specific]:**

- Not using `const` where possible
- Manual memory management that could use stack allocation or `alloca`
- String handling without bounds checking (`strcpy` vs `strncpy`/`snprintf`)

**[Nix-specific]:**

- Inline derivations that could use `mkDerivation` patterns
- Repeated `pkgs.lib.optionalString` blocks that could be factored

**[LuaJIT-specific]:**

- Building strings/byte output in a hot loop with a sequence table + `table.concat` (or `..` concatenation) instead of `string.buffer` (`require("string.buffer")`). Use `buf:put` for appending strings; for **per-byte raw-byte output** use the FFI path -- `buf:reserve(n)` returns a `uint8_t*`, write bytes directly (`ptr[i] = b` / `ffi.copy`), then `buf:commit(used)` -- to eliminate per-byte `string.char` allocations (measured ~5x in practice). Note: `ffi.copy` of 1-3 byte chunks is _slower_ than `:put`, so reserve the FFI path for genuine per-byte output.
- Per-byte `string.byte`/`string.char` in loops where reading via `ffi.cast("const uint8_t*", str)` would skip the call overhead (measure -- sometimes marginal).

**[General]:**

- Not using the language's pattern matching, destructuring, or iterator facilities
- Reimplementing standard library functionality

### 10. Memory Safety and Resource Leaks

Principle: Segfaults and leaks suck. So do security issues.

Look for:

- **[Zig]** Missing `defer allocator.free()` or `defer file.close()` after acquisition
- **[Zig]** Pointer lifetime issues: returning a pointer to stack-local data, storing a slice from a temporary allocation
- **[C]** Missing `free()`, double-free risk, use-after-free patterns
- **Allocation/free scope mismatch:** the `free`/cleanup should live in the same scope as the allocation that owns it (or be handed off via a clearly documented ownership transfer). Flag allocations whose only `free` is in a distant/unrelated scope, or that rely on a caller "remembering" to free with no contract -- prefer `defer`/RAII/cleanup-on-the-spot.
- Unclosed file handles, sockets, or database connections in any language
- **[Zig]** `std.testing.allocator` not used in tests (it detects leaks)
- Resource acquisition without cleanup on error paths

### 11. FFI Boundary Correctness

_Applies to projects with a C FFI layer. Skip for pure single-language projects._

Principle: FFI boundary communications and responsibilities should be clearly documented and enforced where possible.

- **String ownership ambiguity:** Who frees strings passed across the boundary? Is it documented?
- **Null pointer handling:** Does the C side check for null returns? Does the Zig/Rust side check null inputs from C?
- **Parallel FFI surface drift:** If multiple builder/accessor functions exist (e.g., `buildFooResult` and `buildBarResult`), do they all expose the same complete set of fields?
- **Per-item call overhead:** Are there FFI functions called once per item in a loop that should be batched? (e.g., 600K individual `get_entry()` calls vs. a batch API)
- **Symbol visibility:** Are internal symbols leaking into the exported surface? (Zig's default is to export everything)
- **Error propagation:** How do Zig errors cross the FFI? Are they mapped to C error codes/sentinel values consistently? Is there a single source of truth for error definitions?

### 12. Error Handling Gaps

Principle: Failing fast, hard and loudly is good. Silent failures are bad. Log detailed information in a sensible location.

Look for:

- **[Zig]** `catch unreachable` in non-test code -- are you sure that error can never happen?
- **[Zig]** `catch {}` silently swallowing errors
- **[Zig]** Error sets that are too broad (`anyerror`) when a specific set would be safer
- Functions that return success but silently skip work on error conditions
- Missing error context: errors that propagate without enough information to diagnose
- **[General]** Catch-all exception handlers that hide real errors or which group classes of errors together
- **[General]** Error messages that don't include the failing input or context and the expected result constraint. EXCEPTION: PUBLIC error messages on websites should disclose as little information as possible for security reasons, but should still log.

### 13. Subpar Database Access Patterns (via either ORM or SQL, usually connected to postgres or sqlite)

_Applies to projects that use a database. Can skip otherwise._

Principle: Database reading and writing should be fast and use a minimal number of connections and queries.

Look for:

- N+1 queries: Prefer joins, preloads, batching, or set-based operations where appropriate
- Repeated SELECTs in loops or per-record queries that could be collapsed
- Potentially unbounded result sets that don't use pagination or otherwise limit results
- Unsanitized input that could lead to SQL injection or other security issues
- Filtered, joined, sorted, or grouped columns without appropriate indexes
- Indexes without clear utility that slow down writes
- Application-code-only access restrictions that could be database-enforced foreign key constraints
- Migrations that are missing reversals or which permit invalid transitional states
- Migrations that are not idempotent (to the extent possible)
- Destructive migrations without a clear rollback strategy
- Multi-step writes that must succeed or fail together, not being wrapped in transactions
- Not using atomic updates, upserts, locks or constraints where possible
- Retryable jobs that are not idempotent
- Lack of clear backup processes
- Not balancing the tension between excess denormalization and over-normalization
- Joins that accidentally multiply row results or use outer joins when inner joins are appropriate
- Time-based queries that do not factor in time zone or daylight savings time
- Data mishandling: money, timestamps, JSON blobs, enums, soft deletes, tombstoning
- Query patterns that might work fine on development or test data but which might explode in production
- Possible TOCTTOU errors, deadlocks, or other concurrency issues
- Non-redacted sensitive information in logs

---

## Subagent Prompt Template

Each subagent gets a prompt structured like:

<template>
You are reviewing the codebase at {PROJECT_PATH} for: **{DIMENSION_NAME}**

Primary language(s): {LANGUAGES}

Use these tools to explore:

- `codescan search "query"` and `codescan symbols "pattern"` for semantic search
- `dirtree` for file layout overview
- Read files directly for detailed inspection
- {CODE_MINIMAP.md reference if it exists}

Your job is to find issues in dimension: {DIMENSION_DESCRIPTION}

For each finding, report:

- **Severity**: CRITICAL 🔥 / WARNING ‼️ / ADVISORY ⚠️
- **Location**: file_path:line_number
- **Issue**: One-line description
- **Detail**: Brief explanation of why this is a problem and what the fix would be

Write your findings to {TEMP_FILE_PATH}. If you find nothing, write "No issues found."
Focus on real, actionable issues. Do not pad with noise.
</template>

## Output Format: CODE_REVIEW.md

<template>
```markdown
# Code Review -- {Project Name}
**Date:** {YYYY-MM-DD}
**Reviewer:** Claude (deep-code-review skill)
**Scope:** Full codebase audit

## Summary

- **CRITICAL:** {count}
- **WARNING:** {count}
- **ADVISORY:** {count}

## Critical Issues

### {file_path:line} -- {short description}

**Dimension:** {which of the 11}
{detail}

## Warnings

### {file_path:line} -- {short description}

**Dimension:** {which of the 11}
{detail}

## Informational

### {file_path:line} -- {short description}

**Dimension:** {which of the 11}
{detail}

```
</template>

## Common Mistakes When Reviewing

<important>
- **Padding with noise** -- a review with 50 ADVISORY items and no CRITICALs is useless. Focus on real issues.
- **Missing the forest for the trees** -- don't just grep for patterns; understand what the code is trying to do, then ask if it succeeds.
- **Not reading PLAN.md/CLAUDE.md first** -- you need context to judge whether something is incomplete vs. intentionally deferred.
- **Reporting style nits as WARNings** -- naming conventions and formatting are INFO at most, unless they cause actual confusion.
- **Not verifying findings** -- before reporting "function X is never called", grep for it. Before reporting "no test for Y", check.
</important>
```
