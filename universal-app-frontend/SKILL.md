---
name: universal-app-frontend
description: Choose or evolve the shared native desktop frontend stack for Linux, macOS and Windows. Use before scaffolding a GUI, selecting GPUI crates/components, or adapting the Mecha application pattern. Covers package identity, compatible pins, UI/domain boundaries and native qualification; not a mandate to replace an existing frontend.
---

# Universal application frontend

The current desktop default is Rust with the published **`gpui-pre`** snapshot
family and a compatible **`gpui-component`** layer. “GPUI” is the framework name;
it is not sufficient information to choose a Cargo dependency. This is an
owner-selected starting point, not a claim that it is permanently the best
framework or that desktop support proves browser/mobile support.

Read project intent and its existing manifests first. A specified alternative
or established frontend remains in scope; do not migrate it merely because this
skill loaded. If the owner chooses a better stack later, update this decision
and its evidence rather than maintaining contradictory defaults.

## Resolve package identity before writing UI code

1. For a new GPUI app, select a mutually compatible `gpui-pre`, platform,
   component and asset set. Do not start with `gpui = "..."` from crates.io
   because its name matches the requested framework. Check the component's
   actual Cargo manifest and lockfile, including workspace dependencies.
2. Distinguish a Rust import alias from a package name. This is a real observed
   dependency shape, not an instruction to freeze all future apps at 0.3.8:

   ```toml
   gpui = { package = "gpui-pre", version = "=0.3.8" }
   gpui_platform = { package = "gpui-pre-platform", version = "=0.3.8", features = ["wayland", "x11", "font-kit", "runtime_shaders"] }
   ```

   `use gpui::...` is correct with this alias. The snippet is incomplete without
   the matching component/assets and target configuration. See the dated
   [reference application evidence](references/application-pattern.md).
3. Preserve one compatible GPUI type family across app, components, platform,
   assets, macros and tests. A registry package, Git package, patched package or
   different revision may have distinct type identity despite similar names.
   Inspect resolved Cargo metadata/tree and feature unions, not just version
   strings in the app manifest. Pin exact compatible snapshots/revisions and
   commit Cargo.lock and flake.lock.
4. Inspect upstream's matching-version installation guide. A facade such as
   `gpui-kit` may bundle the compatible family; evaluate it explicitly rather
   than mixing facade types with separately selected GPUI/backend types. Do not
   silently migrate working applications to the latest facade or renderer.
5. Build a small vertical slice through `nix build` before implementing the
   application: a real component, text, an icon, keyboard input and one model
   update. A successful dependency resolution or `cargo check` is insufficient
   evidence of linking, rendering or input on the target platform.

An old Git-pinned GPUI application is not necessarily using the stale registry
crate. Identify its actual source before prescribing a repair. Avoid an undated
claim that a crate “has not been updated for a year”; verify release history if
that age matters to a decision.

## Reuse the boundaries, not every historical workaround

- Keep pure application state transitions, formatting and geometry separate
  from GPUI entities, platform I/O and rendering adapters. Inject time and other
  environmental inputs into the pure logic. Persist interactive state and task
  ownership across redraws; do not recreate them in each render.
- Use the component layer for tables, inputs, menus, dialogs, themes and focus
  behavior before inventing replacements. Follow the selected version's
  initialization, asset registration and root/overlay ownership conventions.
  Direct component APIs and facade APIs may wrap roots differently.
- Share domain operations between GUI and CLI through a common client/core
  contract. Keep expensive work off the UI thread; bound concurrency and event
  queues, support cancellation, and reject stale completions after a new request.
- The reference apps use a Rust GUI talking to a separate backend over framed
  transport. That isolates decoder crashes and native-library dependencies.
  It is useful where those costs apply, not mandatory for every app. A pure-Rust
  app may share an in-process core; explicit C ABI integration is another choice.
  Select and document the boundary before copying process-launch ceremony.
- With a backend process, test framing, partial reads, cancellation, crashes,
  exit status and child cleanup. Report an internal failure as such, not as a
  domain verdict. Privileged/licensed operations are enforced by the core;
  hiding a GUI button is not enforcement. Use pointer-plus-length binary buffers
  and explicit ownership when crossing a C ABI.
- Use semantic theme colors, readable contrast, scalable layouts, visible
  focus and keyboard navigation. Check light/dark themes, high DPI, narrow
  windows, long translated strings and assistive technology on actual targets.
  Use the shared `i18n` skill for locale scope, catalogs, RTL and enforcement.

## Build, packaging and qualification

Follow `cross-platform-project-build-arch`: Nix is required and `nix build`
constructs artifacts. Language tools run inside derivations. Preserve complete
bundles, adjacent resources and helpers; do not infer the shipping target from
historical directory names such as `linux/`. Use the shared PF/VARIANT names.

Inspect the exact platform crate features and patches. Test installed artifacts
away from the checkout: fonts, icons and shaders must not need build-machine
source paths. The reference apps carry Windows fixes; examine their provenance
and reproduce the relevant regression before copying or dropping a patch.
Review dependency license metadata/notices for the exact resolved graph; a
component library's license alone does not describe all transitive dependencies.

Use `test-isolation` for filesystem/process tests and `performance-profiling`
for feedback latency. Keep pure model tests fast; add focused GPUI interaction
tests and real native smoke checks. Headless/test-platform success does not
establish visible rendering, accessibility, GPU compatibility or release signing.
Record compile, native runtime, visible UI and distribution qualification
separately per supported target. Browser/WASM or mobile work needs its own
capability and packaging check; “universal” is not evidence for those targets.

## Keep this guide useful

When a recurring issue exposes a missing lesson, update this skill or its
reference with the exact version, reproduction and verified remedy. Do not add
speculative fixes, private operational details or an entire incident transcript.
Keep project-specific implementation changes in that project's plan; this skill
does not claim the fleet has already adopted a new stack or pin.
