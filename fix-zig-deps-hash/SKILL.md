---
name: fix-zig-deps-hash
description: Use when nix build fails with zigDeps/zigDepsHash mismatch, build.zig.zon deps changed, or "hash mismatch"/"fixed-output derivation" errors appear.
---

# Fix Zig Deps Hash

## Overview

When Zig dependencies change (new commit pinned in `build.zig.zon`), the `zigDepsHash` in `flake.nix` becomes stale and `nix build` fails with a hash mismatch. This skill automates the detect-extract-update-retry cycle.

<when_to_use>
- `nix build` fails with "hash mismatch" mentioning the zigDeps derivation
- You just updated a dependency URL or hash in `build.zig.zon`
- You bumped a dependency to a new commit/version
- Error contains "fixed-output derivation" and "got: sha256-..."
</when_to_use>

## Workflow

### Step 1: Set to fakeHash

Find the `zigDepsHash` line in `flake.nix` and set it to the Nix fake hash:

```nix
zigDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

Or use `pkgs.lib.fakeHash` if the flake uses that pattern:

```nix
zigDepsHash = pkgs.lib.fakeHash;
```

### Step 2: Run nix build

```bash
nix build 2>&1
```

This will fail, but the error output contains the correct hash. Look for a line like:

```
  got:    sha256-xYzAbCdEfGhIjKlMnOpQrStUvWxYz1234567890AB=
```

### Step 3: Extract and update

Copy the `sha256-...` hash from the error output and replace the `zigDepsHash` value in `flake.nix`:

```nix
zigDepsHash = "sha256-xYzAbCdEfGhIjKlMnOpQrStUvWxYz1234567890AB=";
```

### Step 4: Verify

```bash
nix build
```

This should now succeed. If it fails again with a DIFFERENT hash mismatch (rare, can happen with transitive deps), repeat from Step 2.

## For linkFarm Projects

Some projects (codescan, chatscan) use `linkFarm` + `--system` instead of `zigDepsHash`. For these:

1. The dependency hash lives in individual `pkgs.fetchgit`/`pkgs.fetchzip` calls
2. Update the specific dependency's `hash` field
3. The cache key name (e.g., `sqlite_vec-0.1.7-alpha.2-4Cdt0Ov...`) may also change -- check `build.zig.zon` for the new URL/hash to derive it

The fakeHash trick works the same way for individual fetch calls.

## Common Mistakes

<important>
- **Forgetting to also update `checks` derivation** -- if the test derivation copies zigDeps separately, it uses the same hash. Both should reference the same `zigDeps` binding.
- **Editing the wrong hash** -- projects may have multiple hashes (for different deps). Match the derivation name in the error to the right variable.
- **Stale local Zig cache** -- if `nix build` succeeds locally but CI fails, clear `~/.cache/zig` and retry.
</important>
