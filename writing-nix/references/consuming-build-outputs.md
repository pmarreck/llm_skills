# Consuming build outputs in place

A Nix build's product is its store path. Run it, link against it, test it and
publish it from there. A project's `./build`, `./test` and `./run` never copy
their own outputs out of `/nix/store`, and nothing ever searches the store to
find one. Needing either is a sign that a path Nix already knows was not asked
for, or that a consumer hardcodes a compiler's scratch directory.

This reference owns how Nix outputs are reached. The
[cross-platform-project-build-arch](../../cross-platform-project-build-arch/SKILL.md)
skill owns the directory names, platform tokens, `CANONICAL_IMPL` selection and
publication rules that the examples below follow.

## Ask Nix for the path

| Need | Mechanism |
|---|---|
| A product the project keeps using | `nix build .#pkg --out-link LINK` (`-o`): a symlink that is also a garbage-collection root |
| A path for one command | `nix build .#pkg --no-link --print-out-paths`, or `nix eval --raw .#pkg.outPath` for a path that may not be built yet |
| A dependency inside Nix code | `${pkgs.foo}`, `${inputs.engine}`, `lib.getExe pkgs.foo` |
| Run a product once | `nix run .#pkg -- ARGS` |
| A tool on PATH while developing | list it in the devShell's packages |
| Another project's product | a locked flake input, never `../sibling/result` |

Plain `result` is overwritten by the next `nix build` in that directory, so a
project that keeps more than one output (profiles, implementations, platforms,
test fixtures) gives each its own named out-link. A `--no-link` path has no
root and can be collected, so use it only within the command that asked for it.

Never locate a product with `find`, `rg`, `ls` or a glob over `/nix/store`,
including "the newest path matching the package name". The match is not tied
to the current source, and the scan itself can saturate storage. See
[diagnostics and activation](diagnostics-and-activation.md).

## Retained out-links are the product tree

Each implementation, platform and profile is one flake package whose `$out` is
a complete installation tree (`bin/`, `lib/`, `include/`, `share/`,
`Applications/`). Its retained out-link sits at the product-tree path the
build-architecture skill defines, for example:

```sh
nix build ".#tool-zig-release" --out-link zig-out/linux-amd64/musl/release
nix build ".#tool-rust-release" --out-link rust-out/linux-amd64/gnu/release
```

The link is read-only and ignored by Git. Compiler caches and incremental
scratch (`.zig-cache/`, Cargo's `target/`, `.lake/`, Roc's package cache) stay
somewhere writable and are never a product. If an existing consumer expects a
flat `zig-out/bin` or `target/release`, change the consumer to take the product
directory as a parameter; do not recreate that layout by copying.

An out-link is an indirect root tied to the link's own path. Renaming or moving
the link orphans the root; follow the build-architecture skill's
`nix-store --add-root` procedure when a verified product has to be registered
under a final name.

## The command on PATH

Shell PATH setup admits only `bin/<PF>/` for the current platform, plus generic
`bin/` for portable scripts. The command there is a relative symlink into the
retained out-link of the canonical implementation's product:

```text
bin/linux-amd64/tool -> ../../zig-out/linux-amd64/musl/release/bin/tool
zig-out/linux-amd64/musl/release -> /nix/store/...-tool
```

`./build` reads `CANONICAL_IMPL`, builds that implementation's package for the
host platform, verifies the product, then publishes. Because `nix build
--out-link` replaces its link only after a successful build, the command on
PATH is always the latest successful build of the canonical implementation, and
a failed build leaves the previous one working. Other implementations get
their own out-links and stay runnable at their namespaced paths; they never
occupy `bin/<PF>/`. A foreign-platform build never touches the host's entry.

Replace the `bin/<PF>/` link atomically: create the new link under a temporary
name in the same directory and rename it over the old one. The link's own path
does not change, so a shell's command hash stays valid across rebuilds.
Nothing under `bin/<PF>/` is a copied binary.

## Development

- The devShell supplies the pinned toolchain for editors, language servers and
  a fast compile-and-check loop. That loop writes to compiler-owned scratch.
  Its results are feedback, not products: they are not published to
  `bin/<PF>/`, and `./test` does not accept them.
- A debug or safety-checked build that someone will run is its own flake
  package and its own out-link (`.../debug`, `.../ReleaseSafe`). `./build
  --debug` selects that package; it does not fall back to a bare compiler.
- Publishing a debug profile to `bin/<PF>/` is an explicit choice. The default
  publication is the optimized profile, and the debug product announces itself.

## Test

- `./test` builds the exact prerequisites it needs with named out-links, then
  hands their paths to each suite through explicit variables or arguments.
  Suites do not hardcode an output directory and do not resolve the command
  from PATH, so a stale installation cannot make them green.
- Fixtures that only tests need (a symbol-inspection archive, a probe binary)
  are separate package outputs or separate packages, reached the same way.
- For CI, expose the suite as a flake `checks` derivation that takes the
  package as an input: `nix flake check` builds only `checks`. Inside that
  derivation, copying declared inputs into the build directory is ordinary
  packaging and is not the host-side copy this reference forbids.
- A test that needs a writable copy of a product (to corrupt it, or to check
  relocation) asks for it explicitly in disposable scratch under `TMPDIR`. On
  a host with the copy guard, the wrappers refuse this, so do it inside a
  check derivation or build the fixture as a package.

## Release

- Assemble what customers download in a derivation: an archive, installer or
  bundle as a `dist` package. Hash and verify that output. A host-side `cp`
  into `dist/` is not a release build.
- Other Nix machines receive closures with `nix copy --to`.
- Nix is the required build context, not an allowed runtime precondition for a
  user-facing executable or application. A store-hosted development output may
  use store paths while it is being assembled, but the shipped product must
  start and perform its self-contained operations without a Nix installation,
  store, profile, shell, or environment variables supplied by a devShell.
- Hosts without a Nix store, native Windows among them, receive the `dist`
  artifact and unpack it. Their `bin/<PF>/` entries come from that delivery,
  not from a link into a store that does not exist there.
- Signing, notarization and stapling need credentials that must not enter a
  derivation or the store, and they modify the product. They run host-side on
  a writable copy of the derivation-built bundle, in disposable scratch, as a
  separately authorized release step.

### Runtime-independence gate

Make this a blocking package or release check, not a manual observation:

1. Run the exact shipped executable from disposable scratch with Nix-specific
   environment variables removed and a deliberately unusable `PATH` for every
   operation that is meant to be self-contained. Do not substitute a source
   wrapper, dev build, injected sidecar path, or command resolved from the
   developer's normal `PATH`.
2. Inspect the platform loader metadata. On Linux, reject an interpreter or
   shared-library dependency when the product promises a static executable;
   otherwise allow only the product's declared system runtime. On macOS and
   Windows, system frameworks and operating-system libraries are not Nix
   dependencies, but Nix-store loader paths, rpaths, DLL locations, resources,
   and helper executables are failures.
3. Inspect both the artifact bytes and its closure. Reject embedded
   `/nix/store/` paths in a standalone distribution, and use
   `nix-store -q --references` or `nix path-info -r` to prove that the closure
   matches the declared runtime contract. A successful `nix build` proves only
   construction, not portability.
4. Exercise the installed or unpacked distribution shape. If the program
   intentionally launches an external command, test startup and independent
   features with that command absent, then test the integration through an
   explicit fixture. Do not confuse an intentional user-selected subprocess
   with a hidden dependency needed for the product itself to start.

Language-specific skills own compiler and linker mechanics; this skill owns
the invariant and gate. They should route here rather than restating weaker or
language-specific versions of the runtime contract.

### Linux: one libc per project, no Nix paths (owner policy, 2026-11-19)

Anything shipped to run outside Nix must start on other Linux distributions.
Its interpreter, `NEEDED` entries, RUNPATH and bytes name no `/nix/store`
path. The Nix package itself may use store paths; the standalone artifact
may not.

Each project chooses one libc for all of its Linux builds, musl or glibc,
according to its requirements. That one libc covers shipped executables,
test binaries and archives alike, so the suite exercises the libc that
ships. Never mix them within a project: behavior differences between glibc
and musl are hard to diagnose. Record the choice and its reason in the
project's intent or design document.

- **musl, fully static (the default):** for programs that need nothing from
  the host beyond the kernel, such as CLIs, services and build tools. The
  executable has no interpreter and no `NEEDED` entry. Size is the accepted
  cost; reduce it with link-time dead-code elimination and debug stripping
  (see the language skills).
- **glibc, dynamic:** required when the program must load libraries the host
  installs. These include GPU drivers and their loaders (Mesa, NVIDIA,
  Vulkan drivers, CUDA, NVENC, VA-API), display and input (Wayland, X11,
  xkbcommon) and audio servers. They are glibc shared objects: a static
  program cannot load them, and musl cannot load glibc libraries. GUI and
  GPU applications therefore use glibc.
  - Use the distribution-standard interpreter path
    (`/lib64/ld-linux-x86-64.so.2` on x86_64, `/lib/ld-linux-aarch64.so.1`
    on arm64), never a store path.
  - Limit `NEEDED` to a declared host runtime: glibc's own libraries plus
    the system graphics, display and audio libraries. Link anything else
    statically, or bundle it beside the binary and find it through a
    `$ORIGIN` RUNPATH.
  - Declare a glibc floor. A binary needs a host glibc at least as new as
    the newest `GLIBC_x.y` version it requires (`readelf -VW`, `objdump -T`).
    Otherwise the loader refuses to start it, with ``version `GLIBC_2.39' not
    found``. Linking against nixpkgs' glibc sets that floor near the build's
    own glibc, even with no new API in use. Measured on BeamFlix (2.42 build,
    2026-11-19), its required versions came from four sources:
    - 2.34 for `__libc_start_main`, `pthread_*` and `dlopen`, from the
      libpthread and libdl merge into libc;
    - 2.35 and 2.38 for new symbol versions of old math functions (`hypot`,
      `fmodf`);
    - 2.39 for `pidfd_spawnp`, which Rust's standard library references
      weakly;
    - and that weak reference's version requirement is not marked weak, so it
      still blocks startup on older glibc.

    For reference: Ubuntu 22.04 ships 2.35, Ubuntu 24.04 2.39, Debian 12
    2.36, Debian 13 2.41, RHEL 9 2.34, RHEL 10 2.39.

    To lower the floor, link against an older glibc. Zig targets one
    directly, for example `x86_64-linux-gnu.2.28`.
  - A lower floor costs no runtime improvement. glibc is loaded from the
    host, so a program built for an old floor still gets the host's faster
    string, memory and math routines, malloc changes, restartable sequences
    and security fixes. The floor only limits which new functions the
    program may call.
  - Owner stance (2026-11-19): the fleet's main user currently runs
    bleeding-edge distributions, so a glibc project may keep the floor its
    Nix build produces for now. It must still state that floor in its
    documentation, and choose an oldest supported distribution before
    distributing to other users.
  - On NixOS, a standalone glibc artifact needs `nix-ld` or an FHS
    environment; NixOS users run the Nix package instead.
- **Never static glibc.** A statically linked glibc still loads its build's
  shared libraries at run time for name service lookups (users, hosts),
  `iconv` and `dlopen`. Rust's standard library reaches `getaddrinfo` and
  `getpwuid_r`; with rustc 1.97.0 and glibc 2.42, a `+crt-static` gnu link
  under Nix's wrapper printed those warnings and then failed ("DSO missing
  from command line").
- **musl routes in Nix:**
  - C: `pkgs.pkgsStatic.stdenv`, a musl cross toolchain from the build
    platform, cached on cache.nixos.org.
  - Rust: `pkgs.pkgsStatic.rustPlatform.buildRustPackage`, whose compiler is a
    cached cross rustc. Do not use `pkgsMusl` for Rust: its rustc is a native
    musl compiler that was not cached and builds from source.
  - Zig: build for `<cpu>-linux-musl`; Zig bundles musl and links it
    statically.
  - When a musl project must link a shared library (for example a test that
    loads one), `pkgs.pkgsCross.musl64` keeps it on musl. Confine that to
    test-only artifacts.
- **Archives** linked into a program must be built for that program's libc.
  A library consumed by projects with different choices should ship one
  flavor per libc, and the library's own suite must test each flavor it
  ships.
- **macOS** cannot be fully static, because libSystem is always dynamic. The
  general gate above applies there.

Gate each shipped Linux artifact mechanically, as a required `./test` check:

1. Program headers (`readelf -lW`, `readelf -dW`):
   - static musl: no `Requesting program interpreter` line and no `NEEDED`
     entry;
   - glibc: the standard interpreter path, `NEEDED` within the declared
     list, no RPATH or RUNPATH outside `$ORIGIN`, and no `GLIBC_` version
     newer than the declared floor.
2. No `/nix/store/` string in the artifact's bytes. Check with
   `strings -a | grep -c`.
3. Run it where Nix is absent:
   - Static musl: run it alone in an empty root, for example
     `bwrap --unshare-all --ro-bind BIN /bin/prog --dev /dev --proc /proc /bin/prog ...`,
     with only its input files bound. A dynamic binary fails there with
     `execvp ...: No such file or directory`.
   - glibc: run it inside a root filesystem of the oldest supported
     distribution, such as a container image or an extracted rootfs under
     bwrap.
   - GPU and display features: exercise them on a machine that has the
     drivers.
4. Add a control: the same check must flag a known-bad binary, such as a
   dynamic Nix-built one. This proves it reads real program headers rather
   than passing on empty output.

## The copy guard override

Where the shared copy guard wraps `cp`, `install` and `rsync`,
`ALLOW_NIX_STORE_COPY` is reserved for release delivery:

1. the writable copy that a credentialed signing or notarization step needs;
2. sending a derivation-built `dist` artifact to a destination that has no Nix
   store, when the transfer tool is one the guard wraps.

It never appears in `./build`, `./test`, `./run`, a devShell hook or a check,
and it is never a way to obtain a dependency or to place a product where a
consumer expects it. Reading a store path in place needs no override.

## Language notes

Match every detail to the project's pinned toolchain; these describe where
products and scratch normally sit, not a builder's exact options.

- **Zig.** `zig build --prefix "$out"` inside the derivation installs the
  product tree. Static archives and headers belong in `$out/lib` and
  `$out/include` for C ABI consumers; a consuming Zig project takes the module
  through its ZON dependency, and other consumers take the package as a flake
  input. The target triple (`x86_64-linux-musl`) is a build argument, while the
  out-link path uses the fleet platform token.
- **Rust.** Cargo's `target/` is a cache with a builder-defined layout. Write
  an explicit install phase that places the named binaries, `staticlib` or
  `cdylib` outputs and any generated header into `$out`. A Rust consumer of
  another Rust project depends on its source through Cargo, per
  [dependency portability](dependency-portability.md), not on a compiled
  store path.
- **Roc.** `roc build` emits one executable; install it into `$out/bin`.
  Platforms and packages named by URL in the application header must be
  supplied by declared fetchers, since the sandbox has no network and no user
  package cache.
- **Lean 4.** Lake builds under `.lake/build` and resolves dependencies from
  `lake-manifest.json`; prefetch those sources and install the executables and
  any exported libraries into `$out`. Check the runtime closure of the result
  before treating it as portable.

In every language the consumer-facing shape is the same: one package per
implementation, platform and profile, a complete tree under `$out`, a named
out-link, and `bin/<PF>/` pointing only at the canonical one.

## Sources

- [nix build: `--out-link`, `--no-link`, `--print-out-paths`](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-build)
- [nix run](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-run)
- [nix copy](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-copy)
- [nix flake check](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-check)

Reviewed 2026-11-19. The command pages were confirmed reachable and to document
the named flags; the language notes were not re-checked against upstream
documentation and must be verified against each project's pinned tools.
