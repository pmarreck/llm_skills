# Application evidence and dependency checkpoints

Inspected 2026-10-23. These are source observations, not a fresh build or runtime
certification. Re-read live manifests before reusing a pin; prose architecture
documents can lag source and build policy. Paths below are relative to each
reference project's root; no access to those private projects is required to
understand the shared guidance.

## Mecha Validate (`validate_gui`)

- `gui/Cargo.toml`: Rust frontend with `gpui` aliased to `gpui-pre =0.3.8`;
  `gpui_platform` aliased to `gpui-pre-platform =0.3.8`, with `wayland`, `x11`,
  `font-kit` and `runtime_shaders` features.
- Component source: `longbridge/gpui-component` revision
  `ed27c6293b585acc40c10be7138534243bee5841`. The asset dependency's Rust key
  `gpui-component-assets` aliases package `gpui-kit-assets` at that revision.
  Nix stages the component sources; Cargo patches component, assets, macros
  and base to those staged paths for offline builds.
- The staged component workspace identifies component version 0.7.1 and pins
  its GPUI/platform snapshot to exactly 0.3.8. This independently confirms the
  app's package pairing; the app alias alone would not.
- Test dependency uses the same `gpui-pre` version with `test-support`, rather
  than introducing a second framework source just for tests.
- `gui/third_party/gpui_windows/PROVENANCE.md`: patched `gpui-pre-windows`
  0.3.8, recorded Zed source revision
  `279fe070bb389b79652e52065b2f001edcc0b11b`. Fixes cover embedded shader source,
  optional Direct Manipulation, a DirectWrite fallback and avoiding an extra
  ICU string-length import. Verify whether each remains necessary at a new pin.
- Release-Windows profile keeps debug assertions for the selected runtime-shader
  implementation. Embedded SVG assets also use `rust-embed`'s `debug-embed`.
  These are version-specific requirements; do not generalize them to all Rust
  release builds or confuse their presence with successful Windows execution.
- `gui/src/serve.rs`, `validate-serve/` and `shim/` show the process/transport
  boundary. `ARCHITECTURE.md` and
  `docs/rust-gpui-zig-backend-shim-pattern.md` explain its motivation, but include
  historical pins, names, non-Nix Mac build descriptions and planned protocol
  features. Source and current Nix-required policy override stale recipes;
  inspect implemented protocol handlers before claiming feature support.

## Mecha RotShield (`entropy_shield`)

- `linux/gui/Cargo.toml` is a cross-platform GPUI client despite the directory
  name. At inspection it still selects Git GPUI and platform from Zed revision
  `1d217ee39d381ac101b7cf49d3d22451ac1093fe`, with the same four platform features.
- Its components/assets use revision
  `b7e63cc29018c27bb24788ddb212f4cbdd861334` of `longbridge/gpui-component`.
  This is an older matched Git family, not evidence that this checkout has
  already migrated to published `gpui-pre` packages.
- `linux/Cargo.toml` separates `client`, `gui` and `mrs` workspace members.
  The GUI consumes `rotshield_client`; the CLI does not need GPUI. The workspace
  patches Git `gpui_windows` and configures its runtime-shader build profile.
- Reuse client/domain boundaries and installed-artifact checks. Do not copy the
  old dependency pins into a new app by default or start a migration without
  checking the current project work and approval scope.

## Dependency preflight

Before implementing more than the vertical slice, record:

1. Actual package names, aliases, registry/Git sources, revisions and lockfile
   identities for GPUI, platform, components, assets and macros.
2. The component's matching upstream manifest and selected platform features.
3. Local patches with provenance and a concrete regression they address.
4. Nix package/check targets, Rust/toolchain pins and required platform SDKs.
5. Evidence per target: dependency resolution, link, native launch, visible
   text/icons/input, packaging/resource lookup and signature verification.

Use Cargo metadata/tree from the pinned Nix environment for inspection. Look
for incompatible duplicates in the connected UI type graph; unrelated duplicate
dependency versions elsewhere are not automatically defects. Keep a passing
lockfile and rollback point before changing this family together.

## Upstream checkpoints

Checked 2026-10-23; consult versioned documentation for the selected pin:

- [GPUI Kit getting started](https://gpui-kit.com/docs/getting-started/) now
  presents `gpui-kit` as a facade over GPUI, components, base and assets. Its
  direct-GPUI example aliases `gpui-pre` and `gpui-pre-platform` at 0.3.9.
  That newer documentation does not certify the reference apps on 0.3.9.
- The same guide places macOS `font-kit` on the platform crate and warns that
  missing it can leave a window with no text. Check visible text, not just a
  successfully opened window.
- Facade initialization owns its root/overlay setup. Do not combine that sample
  with a direct-component sample that also adds a root without checking the API.
- [GPUI Component source](https://github.com/longbridge/gpui-component) and its
  selected Cargo manifest are the authority for its required snapshot family.

The observed new-project preference remains `gpui-pre` plus compatible
components. A facade or alternative renderer can reduce configuration work, but
adoption requires a tested compatibility decision, not a name-based assumption.
