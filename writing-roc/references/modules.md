# Modules, platforms and version-sensitive APIs

Sources reviewed 2026-10-04 against the official revision recorded in `../SKILL.md`.

## Type modules and public APIs

`Label.roc` must declare the nominal type `Label` at top level. Put public
functions/constants/nested types in its associated `.{ ... }` block; unrelated
top-level helpers are private. A header like old `module [name]` is not the
current type-module pattern. For utilities with no constructible values, use
`Util :: [].{ ... }`. A type alias alone is not a supported module export at
the reviewed revision.

```roc
# Label.roc
Label :: { text : Str }.{
	new : Str -> Label
	new = |text| { text: normalize(text) }

	to_str : Label -> Str
	to_str = |label| label.text
}

normalize = |text| text.trim()
```

Elsewhere, `import Label` permits `Label.new(" example ")` and the associated
method `label.to_str()`. It does not expose `normalize` or the opaque backing
record. `import Label as L` renames the import; `exposing [new]` brings an
associated item into unqualified scope.

Directory traversal uses `/`, nested type selection uses `.`. For example,
`import Internal/Parser` loads `Internal/Parser.roc`, while `import Url.ParseErr`
selects a type within `Url.roc`. Package imports begin with the lowercase
alias, e.g. `import json.Parser`. Import cycles are disallowed; place mutually
recursive types together rather than creating cyclic modules.

Source: [module rules](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/modules.md).

## App/package/platform boundary

```roc
app [main!] { pf: platform "../platform/main.roc" }
import pf.Stdout

main! = |_args| {
	Stdout.line!("Hello")?
	Ok({})
}
```

This is a shape example, not a universal entrypoint contract. Inspect the
selected platform's `requires` declarations and actual `Stdout` API before
using it. Downloaded platform URLs identify immutable content; retain the
project's compatible URL/hash rather than inventing a current release URL.
Headerless apps can use the compiler's built-in Echo platform; that is not a
general filesystem/network platform.

A `package [Label] {}` header exposes the package's type modules. Packages
using platform functionality must agree with the app's selected platform.
The platform's host, commonly Zig or Rust, supplies allocation and I/O, calls
the app entrypoint and owns foreign-function access. Cross-compiling an app
therefore requires a compatible host artifact; Roc syntax alone does not
guarantee every OS/architecture is supported.

Sources: [platform architecture](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/platforms.md),
[packages](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/packages.md).

## Toolchain and advanced-feature traps

At the reviewed revision, upstream's Nix flake is in `src/flake.nix`, not
the repository root. A candidate immutable source reference is
`github:roc-lang/roc/1a4df199210309bbb6befb1322f7435361bd01e1?dir=src`.
Its `.packages.<system>.roc` output builds the compiler in Debug and uses
`zig_0_16`; `build.zig.zon` also requires at least Zig 0.16.0. Do not assume
the newest Zig release is the intended compiler build toolchain.

The upstream flake marks Darwin compiler packages broken at this revision.
This skill does not claim that those outputs were built successfully. Verify
native packaging before promising Mac support; ignoring `meta.broken` alone
does not repair a build. Keep package fetching declared in Nix so ordinary
app tests can run without network access in the sandbox.

Sources: [upstream Nix flake](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/src/flake.nix),
[compiler build manifest](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/build.zig.zon).

- A header `roc: "nightly-..."` pin diagnoses mismatches but is not an enforced
  Nix toolchain selection. `roc fmt` can update an older nightly pin; inspect
  formatter diffs and do not treat a pin rewrite as a reviewed upgrade.
- In generic APIs, current constraints use `where [a.to_str : a -> Str]`.
  Do not copy older `implements`/ability examples without checking the dialect.
- Nominal type identity depends on defining module content and imported module
  content. Even structurally identical types can become distinct after a
  dependency change. Inspect the resolved module graph before adding casts or
  weakening a public API to work around a mismatch.
- Documentation sometimes contains planned features. Use compiler checks
  before adopting alias modules, record builders or newly added syntax; a
  published design paragraph is not proof of implementation.
- A custom `--target=luajit` backend is a fork feature, not an assumed upstream
  CLI option. Inspect that fork's help, tests and limitations separately.

Sources: [version pins and nominal identity](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/modules.md#pinning-a-roc-version),
[generic types](https://github.com/roc-lang/roc/blob/1a4df199210309bbb6befb1322f7435361bd01e1/docs/langref/types.md#where-clauses).
