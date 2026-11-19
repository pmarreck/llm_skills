# Build revisions

Use `rN-abcdef` to label a build independently of its product version. Generate
that label from Git metadata rather than maintaining another version counter.

- The primary branch is `yolo`. A fork uses its declared primary integration
  branch when it retains the upstream name.
- Select the base from the primary branch's recorded first-parent history. For
  a commit on that line, the base is the built commit itself. For a topic build,
  use the closest commit on that line that is an ancestor of the built commit.
  This keeps unmerged topic commits out of the primary-branch count.
- `N` is the decimal result of `git rev-list --count "$primary_base"`, using
  complete history. Count all commits reachable from the base, including merged
  commits. First-parent traversal selects the base, and the count includes its
  full ancestry.
- The suffix is the first six lowercase hexadecimal digits of the **built**
  commit hash. Store its full hash in machine-readable provenance. A display
  prefix can collide, so manifests and caches that require unique source IDs
  use the full hash.

For example, two branches off a base with 182 reachable commits could produce
`r182-6a2cfe` and `r182-b799a0`. Rebuilding either source from its recorded base
produces the same revision, regardless of later advancement of the branch.

Capture the built commit, primary base and count in a Git-aware build setup or
CI step. Pass them as explicit inputs to the Nix build and embed the resulting
revision in the artifact so `--about`, GUI About boxes and release receipts can
agree. Preserve the metadata with source archives and detached releases. A
shallow checkout needs complete history or already verified metadata for the
exact source and base. Report unavailable provenance explicitly when the count
cannot be established. Keep a dirty working tree status separate from the
revision and require exact clean source provenance for releases.
