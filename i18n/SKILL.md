---
name: i18n
description: Use when starting or expanding any user-facing UI (CLI, TUI, web, GUI) where translations, locales, or multilingual support are mentioned, planned, or implied. Establishes a canonical 50-locale set, compile-time enforcement, bilingual-error rule, RTL handling, and --lang/--help translation conventions. Also use when reviewing existing UI for i18n readiness.
---

# i18n — internationalization discipline for user-facing UI

A consistent i18n discipline for any CLI/TUI/web/GUI project: every
shipped tool should support every supported language fully, with
missing translations failing the build rather than silently falling
back to English.

## When to invoke

- A new project has any user-facing strings (CLI help, prompts, error
  messages, web UI labels, GUI menu items)
- Existing project adds a new locale or expands UI
- Code review surfaces a missing-translation fallback, an untranslated
  error string, or a hardcoded English message in user-facing code
- A user asks "should this support languages?" / "is this localized?"

If you're touching user-facing strings AT ALL, check this skill before
deciding the framework.

## The canonical 50 locales

Every new UI project must build infrastructure that can accept strings
for all 50 of these codes (preparation phase), and must enforce them
all once the UI stabilizes (ship phase, defined below):

```
am  Amharic              en  English              mk  Macedonian
ar  Arabic (RTL)         es  Spanish              nb  Norwegian Bokmål
az  Azerbaijani          fa  Persian/Farsi (RTL)  nl  Dutch
bg  Bulgarian            fi  Finnish              pa  Punjabi
bn  Bengali              fil Filipino             pl  Polish
bs  Bosnian              fr  French               ps  Pashto (RTL)
da  Danish               ha  Hausa                pt_br Portuguese (Brazil)
de  German               he  Hebrew (RTL)         ro  Romanian
el  Greek                hi  Hindi                ru  Russian
                         hr  Croatian             sl  Slovenian
                         hu  Hungarian            sq  Albanian
                         id  Indonesian           sr  Serbian
                         ig  Igbo                 sv  Swedish
                         is  Icelandic            sw  Swahili
                         it  Italian              ta  Tamil
                         ja  Japanese             th  Thai
                         km  Khmer                tr  Turkish
                         ko  Korean               uk  Ukrainian
                                                  ur  Urdu (RTL)
                                                  vi  Vietnamese
                                                  yo  Yoruba
                                                  zh_hans Chinese (Simplified)
                                                  zh_hant Chinese (Traditional)
```

**RTL languages in this set (5):** `ar he fa ps ur`. Plan UI layout
mirroring and ANSI escape handling for these.

**Multi-segment codes (4):** `fil` (3-char ISO 639-2), `pt_br`,
`zh_hans`, `zh_hant`. Locale parsers must accept 2/3/4/5/6/7-char
codes via longest-match-with-separator-boundary so `fil` doesn't
collide with `fi` and `pt_br` parses as one unit.

**Why this 50 (the selection lens — preserve in PROJECT_OVERVIEW.md):**
high-computer-penetration languages PLUS deliberately under-served
ones (Hausa, Amharic, Yoruba, Igbo, Filipino) on a "seed adoption where
English penetration is thin" rationale. NOT a top-50-by-speakers list.

## Phase: prepare vs enforce

There are two distinct phases. Pick the correct one before writing
any translation infrastructure.

### Prepare phase (UI not yet stable)

While UI strings are still churning, **build the infrastructure** to
accept translations in any of the 50 locales — but **do not block
builds on missing translations yet** (you'd thrash). What "prepare"
means concretely:

- Strings live in a typed structure that the rest of the code accesses
  by name (not inline). No string is hardcoded at the use site.
- Locale loader exists and can load any of the 50 codes when present.
- Missing-locale path is loud but non-fatal: log a `WARN: i18n
  missing-locale <code>` at startup, surface a banner in dev builds.
- Tests assert "English is complete." Other locales: skip-on-missing
  is OK, but mark these skips visibly.

### Ship/enforce phase (UI stabilizes)

The moment UI strings stop churning weekly (project lead's judgment;
typically post-v1 surface), flip the switch. Now:

- **Missing translation breaks the build.** No silent fallback to
  English. The mechanism is up to the language:
  - **Zig:** every string is a no-default struct field; the compiler
    rejects an incomplete locale literal.
  - **Rust:** same, via struct + `Default` omitted.
  - **TypeScript:** strict interface; tsc rejects missing keys.
  - **Lua:** test-time assertion that every locale table has every key
    from English; CI fails on miss.
  - **Swift:** every string is a stored property; compiler enforces
    init.
- **Tests fail** if any of the 50 locale tables is incomplete OR if a
  new string is added to English without corresponding entries in the
  other 49.
- **CLI alias maps merge at compile time** (Zig comptime / Rust const /
  TS const). Same-name → different-arg is a hard compile error. Same-
  name → same-arg dedupes silently.

  **Cross-locale alias collisions are real, not theoretical.** A real
  comptime guard implementation caught Indonesian `--hanya` (= "only")
  clashing with Hausa `--hanya` (= "path") at build time. Without the
  guard this ships as a silent ambiguity — whichever locale loads last
  wins, and the user gets surprising behavior in their language. The
  same-name→different-arg-fails / same-name→same-arg-dedupes rule
  handled it cleanly. Treat this as evidence: with 50 locales the
  surface for collision is large; the compile-time guard is mandatory,
  not nice-to-have.

## Bilingual errors (always, regardless of phase)

Non-English error messages MUST carry the English original in
parentheses, plus a hint that the English version is for search:

```
Korrekturlesen fehlgeschlagen: Datei nicht gefunden
  (search for: "validation failed: file not found")
```

Users hitting an error in their own language can still Google /
Stack-Overflow the English original. This is non-negotiable and
covers errors only — informational/help/UI strings don't need the
English shadow.

Implementation: error structs hold both `localized_message: string`
and `english_message: string`; the renderer composes them.

## CLI conventions (binding for all CLI/TUI tools)

### `--lang` / locale arg

- Every CLI accepts `--lang <code>` where `<code>` is one of the 50.
- Env vars are honored in this order: `<APPNAME>_LANG` (project-
  specific override, e.g. `MYTOOL_LANG`) → `LANG` → `LC_ALL` →
  `LC_MESSAGES` → `LANGUAGE` (Linux fallback). On macOS, also
  `AppleLanguages` from `defaults read NSGlobalDomain AppleLanguages`.
  On Windows, also `GetUserPreferredUILanguages`.
- `--lang` overrides all of the above.
- Default fallback if no signal: `en`.

### `--lang` is itself translatable

Yes, do it. `--lang` is aliased to its native form in each of the 50:
e.g. `--sprache` (de), `--langue` (fr), `--idioma` (es), `--idioma` 
disambiguated against Portuguese via context, `--limba` (ro), etc.
Passing the localized form ALSO switches output to that language even
without an explicit code — language inference from the flag itself.
The aliases land in the comptime-merged alias map (collision check
applies).

**Locale-code values are NOT translated.** Users pass `fr` or `de`,
not `francais` or `deutsch`. Reasons:
- ISO codes are universal; translating them invites ambiguity (German
  for "Spanish" vs Italian for "Spanish" — different strings, same
  language).
- Keeps the code surface predictable across platforms / env vars /
  config files.
- Localized *flag names* + universal *code values* gives the best of
  both worlds: the user reads their language, the tool reads ISO.

### `--help` translation

- `--help` itself is aliased to its native form per locale: `--hilfe`,
  `--aide`, `--ayuda`, `--помощь`, `--助け`, etc.
- Receiving `--hilfe` ALSO sets output language to German for that
  invocation (no separate `--lang` needed).
- `--help` output (every line of it) translates with the locale.
- Subcommand names accept localized aliases too where practical
  (`build` ↔ `bauen` ↔ `construir`). English forms always work too;
  later args override earlier ones.

## RTL handling

Five locales in the set are RTL: `ar he fa ps ur`. Care points:

- **CLI line composition:** putting localized + parenthetical-English on
  the same line under RTL needs explicit LRM/RLM (Unicode bidi marks) or
  the terminal will reorder confusingly. Wrap the English shadow in
  `‪...‬` (LTR embedding) when emitting under an RTL locale.
- **Tables / aligned columns:** ANSI escapes around RTL strings can
  cause column-width miscalculations. Compute display width via a
  grapheme-aware library, not `strlen`.
- **GUI mirroring:** macOS / GTK / Qt all support automatic mirroring
  per locale; flip the layout direction on locale change, don't
  hand-roll per-widget.
- **Web UI:** set `<html dir="rtl">` for RTL locales; don't try to
  mirror with CSS alone.

If the locale is in `{ar he fa ps ur}` and the output path doesn't
handle bidi correctly, fix the renderer before adding the locale —
don't ship broken RTL.

## Testing requirements

Every project (post-enforce phase) must include these tests:

1. **English-is-complete** — golden test enumerating every UI string
   key. Fails if English misses any.
2. **Every-locale-matches-English-keys** — for each of the 49 other
   locales, assert key parity with English. Fails the build per
   missing key.
3. **Alias-collision** — the merged CLI alias map has no same-name →
   different-arg entries. Compile-time where possible, runtime
   assertion otherwise.
4. **RTL render smoke test** — render a known string in `ar` and `he`,
   capture the byte stream, assert the LRM/RLM marks are present where
   English-shadowed errors are emitted.
5. **Locale-parser sanity** — `parse("fil") == FIL` (not `FI` + `l`);
   `parse("pt_br") == PT_BR`; `parse("zh_hant") == ZH_HANT`; longest
   match wins.
6. **Env-var precedence** — `--lang fr` beats `LANG=de_DE.UTF-8`; chain
   tested top to bottom.

These tests are the enforcement. Without them, the discipline rots.

## Anti-patterns to refuse

- "We'll add other languages later." → If post-enforce, refuse to merge
  unless all 50 land in the same PR (or the project drops to prepare
  phase with a documented reason).
- Silent fallback to English on missing key. Always fatal at compile
  or test time post-enforce.
- Hardcoded English strings at the use site. Strings live in the typed
  locale structure, not inline.
- "It's just an error message, no need to localize." → No. Errors are
  the highest-stakes user-facing strings.
- gettext-style `_("string")` wrapping without compile-time key
  enforcement. Runtime-only checks are insufficient.
- "`--lang` is too much, just use `LANG`." → No. CLI users override
  one-shot; env vars are session state. Both required.

## Suggested module / file layout

Per-project conventions, but a typical shape:

```
src/i18n/
  ├── keys.<ext>          # the typed key registry — single source of truth
  ├── en.<ext>            # English locale (canonical)
  ├── de.<ext>            # ...one per locale...
  ├── ... × 50
  ├── loader.<ext>        # locale loader; env-var chain
  ├── parser.<ext>        # locale-code parser (longest-match)
  ├── bidi.<ext>          # RTL helpers (LRM/RLM, display-width)
  └── tests/
      ├── completeness.<ext>
      ├── alias_collision.<ext>
      └── rtl_render.<ext>
```

CLI side:

```
src/cli/
  ├── args.<ext>          # arg parser
  └── alias_map.<ext>     # comptime-merged from i18n/<locale>.<ext>
```

## When you're scaffolding a new project

If the project will have UI:

1. Drop in `src/i18n/` with the structure above.
2. Define the key registry from day 1 (even if only English is
   populated).
3. Mark the project's phase in PROJECT_OVERVIEW.md ("**i18n phase:
   prepare**" or "**i18n phase: enforce**").
4. List the 50 locales explicitly in `docs/I18N.md` with the
   selection rationale (so future contributors don't relitigate which
   languages).
5. Test #1 (English-is-complete) lands in the same scaffold commit.
   Tests 2-6 land when phase flips to enforce.

## When you're reviewing existing UI work

Walk through this checklist:

- [ ] Are user-facing strings extracted from inline code?
- [ ] Is there a typed key registry?
- [ ] What phase is the project in (and is that explicit somewhere)?
- [ ] If enforce: do tests 1-6 from "Testing requirements" exist and
      pass?
- [ ] If prepare: is the missing-locale path loud (banner / warn) but
      non-fatal?
- [ ] Are errors bilingual with the English-search hint?
- [ ] Are RTL locales handled (LRM/RLM, grapheme-aware width)?
- [ ] Is `--lang` accepted, translated, and overriding env vars?
- [ ] Is `--help` translated and switching locale on its localized
      form?

Findings go in the PR review; refuse the merge if enforce-phase
gaps exist.

## Implementation references

- **Comptime alias-merge collision guard** is the load-bearing
  mechanism behind the cross-locale guarantee. Implementations exist
  in Zig (comptime hash-merge with `@compileError` on conflict), Rust
  (const fn merging with const-evaluable assertions), and TypeScript
  (literal-type union with conflict detection). Pick the most
  idiomatic form for your language.
- **Lossless terminal bidi rendering** for the RTL set typically
  requires a small grapheme-aware width library; pure `strlen` will
  miscount.
