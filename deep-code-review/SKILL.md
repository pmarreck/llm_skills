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
dirtree                          # project file layout
codescan status                  # is index current?
```

Read `CODE_MINIMAP.md` if it exists. Read `PLAN.md` to understand what's been done and what's in progress. Identify the primary language(s).

### Step 2: Dispatch 11 Parallel Subagents

Launch one subagent per review dimension. Each subagent should:
- Use `codescan search`, `codescan symbols`, `dirtree`, and file reads
- Report findings with **severity** (CRITICAL / WARN / INFO) and **file:line** references
- Be language-aware (Zig, C, Nix, or whatever the project uses)

<important>
Give each subagent the project path, the primary language, and a clear scope. Tell them to write their findings to a temp file. Collect and merge results after all complete.
</important>

### Step 3: Compile Results

Merge all subagent findings into `CODE_REVIEW.md` with sections per dimension, sorted by severity within each section.

---

## The 11 Review Dimensions

### 1. Inconsistent, Incomplete, or Undefined Functionality

Look for:
- Functions that are declared/stubbed but not implemented (`TODO`, `unimplemented`, empty bodies)
- Features mentioned in PLAN.md or CLAUDE.md that aren't reflected in code
- Inconsistent behavior between similar code paths (e.g., one validator checks X but another doesn't)
- API surface that promises something the implementation doesn't deliver

### 2. Inadequate Test Coverage

Look for:
- Functions with no corresponding test
- Mapping/lookup functions that don't test every possible input value
- Missing boundary conditions: empty input, max-size input, off-by-one, null/zero, unicode, negative values
- Missing error path testing (does the test suite exercise error branches?)
- Code paths only tested with happy-path data
- **[Zig]** `catch unreachable` in production code that hasn't been tested with the error condition

### 3. Futile Test Coverage

Look for:
- Assertions that test trivially true conditions (`expect(true)`, `expect(1 == 1)`)
- Tests that only verify the test setup, not actual behavior
- Tests that can never fail because they test implementation details that are tautologically correct
- Tests whose assertions don't actually constrain the behavior they claim to test
- Snapshot tests that were auto-accepted without review

### 4. Superfluous or Duplicated Functionality

Look for:
- Two functions that do the same thing with slightly different signatures
- Copy-pasted logic that should be factored out (3+ similar blocks)
- Dead code: functions defined but never called, unreachable branches, commented-out code left behind
- Unused imports, unused variables, unused struct fields
- Wrapper functions that add no value over calling the inner function directly

### 5. Suboptimal, Inconcise, or Disorganized Code

Look for:
- Overly verbose code that could be expressed more clearly
- Deeply nested conditionals that could be flattened (early returns, guard clauses)
- Poor naming: single-letter variables in non-trivial scope, misleading names, inconsistent conventions
- Files that mix unrelated concerns
- Functions that are too long (>100 lines) and should be decomposed
- Magic numbers without named constants

### 6. Algorithmic Complexity

Look for:
- Inner loops that are O(n^2) when O(n log n) or O(n) is achievable (especially: nested linear scans over collections, repeated string concatenation)
- Repeated work inside loops that could be hoisted (precomputation, memoization, lookup tables)
- Unnecessary allocations in hot loops -- estimate ops/iteration
- **[Zig]** Using `page_allocator` directly instead of arena/GPA, large stack buffers that should be heap-allocated
- Estimate the Big-O of the program's hot loops and flag anything worse than necessary

### 7. Files Without Clear Purpose

Look for:
- Files that are suspiciously small (<10 lines) or suspiciously large (>1000 lines)
- Files whose name doesn't match their content
- Utility/helper files that have become grab-bags of unrelated functions
- Files that exist only because of a refactor that was never completed
- Orphaned test files that test modules that no longer exist
- Use `dirtree` for the overview and `codescan symbols --file <path>` to inspect suspicious files

### 8. Not Leveraging Language Features

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
- Building strings/byte output in a hot loop with a sequence table + `table.concat` (or `..` concatenation) instead of `string.buffer` (`require("string.buffer")`). Use `buf:put` for appending strings; for **per-byte raw-byte output** use the FFI path -- `buf:reserve(n)` returns a `uint8_t*`, write bytes directly (`ptr[i] = b` / `ffi.copy`), then `buf:commit(used)` -- to eliminate per-byte `string.char` allocations (measured ~5x in practice). Note: `ffi.copy` of 1-3 byte chunks is *slower* than `:put`, so reserve the FFI path for genuine per-byte output.
- Per-byte `string.byte`/`string.char` in loops where reading via `ffi.cast("const uint8_t*", str)` would skip the call overhead (measure -- sometimes marginal).

**[General]:**
- Not using the language's pattern matching, destructuring, or iterator facilities
- Reimplementing standard library functionality

### 9. Memory Safety and Resource Leaks

Look for:
- **[Zig]** Missing `defer allocator.free()` or `defer file.close()` after acquisition
- **[Zig]** Pointer lifetime issues: returning a pointer to stack-local data, storing a slice from a temporary allocation
- **[C]** Missing `free()`, double-free risk, use-after-free patterns
- **Allocation/free scope mismatch:** the `free`/cleanup should live in the same scope as the allocation that owns it (or be handed off via a clearly documented ownership transfer). Flag allocations whose only `free` is in a distant/unrelated scope, or that rely on a caller "remembering" to free with no contract -- prefer `defer`/RAII/cleanup-on-the-spot.
- Unclosed file handles, sockets, or database connections in any language
- **[Zig]** `std.testing.allocator` not used in tests (it detects leaks)
- Resource acquisition without cleanup on error paths

### 10. FFI Boundary Correctness

*Applies to projects with a C FFI layer. Skip for pure single-language projects.*

- **String ownership ambiguity:** Who frees strings passed across the boundary? Is it documented?
- **Null pointer handling:** Does the C side check for null returns? Does the Zig/Rust side check null inputs from C?
- **Parallel FFI surface drift:** If multiple builder/accessor functions exist (e.g., `buildFooResult` and `buildBarResult`), do they all expose the same complete set of fields?
- **Per-item call overhead:** Are there FFI functions called once per item in a loop that should be batched? (e.g., 600K individual `get_entry()` calls vs. a batch API)
- **Symbol visibility:** Are internal symbols leaking into the exported surface? (Zig's default is to export everything)
- **Error propagation:** How do Zig errors cross the FFI? Are they mapped to C error codes/sentinel values consistently?

### 11. Error Handling Gaps

Look for:
- **[Zig]** `catch unreachable` in non-test code -- are you sure that error can never happen?
- **[Zig]** `catch {}` silently swallowing errors
- **[Zig]** Error sets that are too broad (`anyerror`) when a specific set would be safer
- Functions that return success but silently skip work on error conditions
- Missing error context: errors that propagate without enough information to diagnose
- **[General]** Catch-all exception handlers that hide real errors
- **[General]** Error messages that don't include the failing input or context

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
- **Severity**: CRITICAL / WARN / INFO
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
- **WARN:** {count}
- **INFO:** {count}

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
- **Padding with noise** -- a review with 50 INFO items and no CRITICALs is useless. Focus on real issues.
- **Missing the forest for the trees** -- don't just grep for patterns; understand what the code is trying to do, then ask if it succeeds.
- **Not reading PLAN.md/CLAUDE.md first** -- you need context to judge whether something is incomplete vs. intentionally deferred.
- **Reporting style nits as WARNings** -- naming conventions and formatting are INFO at most, unless they cause actual confusion.
- **Not verifying findings** -- before reporting "function X is never called", grep for it. Before reporting "no test for Y", check.
</important>
