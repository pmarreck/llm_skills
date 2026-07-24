---
name: i18n
description: Use when translations, locales, multilingual support, RTL, bilingual errors, or --lang behavior are mentioned, or when i18n has already been enabled for a CLI, TUI, web, or GUI project. Before introducing i18n to an existing non-localized project, obtain and record an explicit project-owner decision. Establishes the canonical 50-locale set and prepare/enforce discipline.
---

# i18n — internationalization discipline for user-facing UI

A consistent i18n discipline for CLI/TUI/web/GUI projects whose scope
includes localization: every supported language must be supported
fully, with missing translations failing the build rather than
silently falling back to English.

## When to invoke

- A new project explicitly includes localization in its intended scope
- Existing project adds a new locale or expands UI
- Code review surfaces a missing-translation fallback, an untranslated
  error string, or a hardcoded English message in user-facing code
- A user asks "should this support languages?" / "is this localized?"

Touching user-facing strings alone is a reason to check the project's
recorded scope decision, not permission to add i18n infrastructure.

## Scope decision gate

Before adding localization infrastructure to an existing project that has no
i18n support, inspect the project root's `RULES.md` for an
`Internationalization` decision.

- If no decision is recorded, ask the project owner whether to introduce i18n
  before changing code or tests.
- Record the decision in the project root's `RULES.md` with one of three
  statuses: `enabled`, `deferred`, or `declined`, plus the decision owner,
  date/timezone, scope, and a short rationale. Create `RULES.md` if needed.
- `enabled` means apply this skill's prepare/enforce discipline.
- `deferred` means do not add infrastructure now; record the condition or date
  that should reopen the question.
- `declined` means do not add i18n infrastructure unless the project owner
  explicitly revisits the decision.
- Do not ask again while that recorded decision remains applicable.

Personal dotfiles and one-owner utilities are not automatically i18n candidates.
Their economics and maintenance burden differ from distributed software, so
default neither to enabled nor declined—ask once and preserve the answer.

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

**Chinese region→script folding (generic `zh`):** the bare macrolanguage code
`zh` and region-only forms carry no explicit `Hans`/`Hant` script subtag, so the
parser must fold them deterministically instead of failing to match:
- `zh`, `zh_CN`, `zh_SG`, `zh_MY` → **Simplified** (`zh_hans`) — the default.
- `zh_TW`, `zh_HK`, `zh_MO` → **Traditional** (`zh_hant`) — the historically
  Traditional-script regions.
- An explicit script subtag always wins over region: `zh_Hant`, `zh_Hant_HK`
  → Traditional; `zh_Hans` → Simplified. The normal longest-match pass matches
  these first; the region table is only a fallback when no script subtag exists.

This is the same default-to-Simplified-unless-TW/HK/MO rule CLDR/BCP-47
likely-subtags encode, reduced to the three Traditional regions so you don't
have to vendor a full likelihood-subtags database. The pattern generalizes:
any macrolanguage with script variants (e.g. `sr` Cyrillic/Latin) can use a
small region→variant fallback table behind the longest-match parser.

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

## Producing the translations (quality & model selection)

Getting *complete* catalogs is infrastructure (above). Getting *correct*
ones is a separate problem that **varies enormously by language** — and the
failure mode is silent: a general LLM will emit fluent-looking garbage for a
low-resource language that passes msgfmt, placeholder-parity, and even the
completeness gate. **Structural gates prove structure, not meaning.**

Non-negotiable rules (the details, tiers, and current model recommendations
live in the companion **`TRANSLATION_CAPABILITY.md`** — a dated, volatile doc,
re-benchmark per language before trusting it):

- **Probe every new locale before trusting automated output.** Translate its
  keyword list + a couple UI strings + one prose sentence, **back-translate**,
  and eyeball. Anglicized / hallucinated / non-words → it's low-resource;
  do not ship LLM-only.
- **Ground terms in an oracle the model didn't produce** — the language's
  GNOME `.po` files for UI terms, a national/EU terminology DB (téarma.ie,
  IATE, MS Language Portal) for domain terms. Two LLMs agreeing is NOT
  independence (MFIC): they're confidently wrong the same way on hard languages.
- **Pick the model by task and language, not one generalist for all** — a
  translation-tuned model / dedicated MT (NLLB) often beats a bigger chat LLM
  at the *translation* task; a "best language-X LLM" may be tuned to converse,
  not translate.
- **Maker ≠ checker.** Whoever produced a catalog does not approve it; route to
  an independent reviewer (ideally a different model family) and, for
  low-resource prose, a native/community pass — that's the real quality ceiling.
- **Honest incompleteness beats forced garbage.** Keep completeness WARN-only
  until a locale is genuinely verified; **drop** a locale no available tool can
  do faithfully rather than hard-gate hallucinations into the build.

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
- Resolve an explicit application request first: `--lang` overrides
  `<APPNAME>_LANG` (for example, `MYTOOL_LANG`). Do not mutate the
  parent shell's environment.
- Without an application request, defer to the platform's native locale
  resolver; do **not** manually invent an incompatible variable order.
  On Unix, call `setlocale(LC_ALL, "")`. POSIX categories resolve as
  `LC_ALL` → `LC_MESSAGES` → `LANG`. With GNU gettext, message catalogs
  additionally honor `LANGUAGE` as a colon-separated preference list ahead
  of those variables, but only when the active locale is not `C`.
- On macOS, honor an explicit Unix locale first. If none yields a usable UI
  language, use CoreFoundation's `CFLocaleCopyPreferredLanguages()` and pick
  the first supported catalog. Do not parse `defaults` output;
  `CFLocaleCopyCurrent()` describes regional formatting and is not the UI
  language preference. On Windows, use `GetUserPreferredUILanguages()` as
  the equivalent platform fallback.
- `LANG`, `LC_MESSAGES`, and `LC_ALL` are system-locale settings;
  `LANGUAGE` is GNU-gettext-only message-catalog preference. There is no
  generic `LOCALE` environment variable; `LOCALE_ARCHIVE` is a glibc data
  path, not a language selector.
- Fall back to `en` if there is no signal. In enforce phase, an unsupported
  explicit `--lang` or `<APPNAME>_LANG` must fail loudly, not silently select
  English.

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
   match wins. Chinese region-folding: `parse("zh_CN") == ZH_HANS`,
   `parse("zh") == ZH_HANS`, `parse("zh_TW") == ZH_HANT`,
   `parse("zh_HK") == ZH_HANT`; explicit script beats region
   (`parse("zh_Hant_HK") == ZH_HANT`).
6. **Locale-resolution precedence** — `--lang fr` beats
   `<APPNAME>_LANG=de`; the app override beats the native resolver; Unix
   message resolution covers `LC_ALL`, `LC_MESSAGES`, and `LANG`; GNU builds
   cover `LANGUAGE` including its `C`-locale exception; macOS and Windows
   adapters have isolated fallback tests.
7. **Alias-inference disjointness** — if you infer the UI language from a
   *localized* alias present in the args (e.g. `--hilfe` ⇒ German), every
   non-English locale's alias-name set MUST be **disjoint** from the English
   canonical set. Enforce it as a set-classifier over the full cross-product
   (each non-English name × every English name), not a spot check. This is
   the MFIC-correct form: mechanically swept, and it fails on the *specific*
   defect below. **Why it bites (real bug, dirtree 2026-07):** locale files
   are usually seeded by copying `en.zig`, and a translator leaves an English
   canonical token behind un-translated — `ur` kept `note`, `es` kept
   `--color`, `hi` kept `--path`, `nb`/`da` kept `--test`. Because inference
   skips English but returns the *first non-English* locale whose alias
   matches an argument, typing a plain English word (`dirtree note …`,
   `--color`, `--test`) silently switched the entire UI into Urdu / Spanish /
   Danish. The English token still resolves via the English table, so the
   fix is pure deletion from the non-English tables — zero functionality lost.
   A companion behavioral test (`inferLocaleFromAliases([<each English
   canonical token>]) == none`) pins the user-facing guarantee. Corollary:
   coincidental homographs count too — Spanish `color`, Danish `test` are the
   same spelling as English, so they must NOT live in the localized table;
   the English table already provides them.

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
