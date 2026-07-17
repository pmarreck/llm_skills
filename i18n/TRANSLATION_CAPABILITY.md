---
purpose: Per-language machine-translation capability + the source-grounded production workflow for multilingual UI. Companion to SKILL.md.
audience: agent
maintained_by: agent
last_verified: 2026-07-17
volatile: true  # model landscape changes fast — RE-BENCHMARK per language; do not trust specific model names/scores past ~6 months
---

# Translation capability & model selection (per-language)

**Why this exists:** the hardest part of shipping the canonical 50 locales is not the
infrastructure (that's SKILL.md) — it's that **automated translation quality varies
enormously by language**, and the failure mode is *silent*. Verified empirically on the
fsearch project (2026-07); generalizes to any multilingual UI.

## The core finding (non-negotiable, not volatile)

**General-purpose LLMs produce fluent-looking but semantically WRONG translations for
low-resource languages — and that wrong output passes every structural gate.**

- `msgfmt`, placeholder-parity, header, completeness, and even a keyword-guard prove
  **structure, not meaning**. A non-empty, well-formed `msgstr` that is confident
  garbage sails through all of them.
- Observed directly: `gemma4:12b` and `qwen3:8b` "translated" Irish keyword/UI strings
  into **hallucinated non-words** (`uiscint`, `orten`, `córfacha`) and wrong meanings
  (`cuir isteach` = *insert*, not *search*), all structurally valid. Two LLMs (producer +
  reviewer) can be **confidently wrong the same way** — a Claude→GPT review chain does
  NOT catch it for the hardest languages.
- **MFIC consequence:** for low-resource locales you need an oracle whose correctness is
  *causally independent of the model* — a terminology database, a native speaker, or an
  existing human reference translation. Not "another LLM."

## The source-grounded workflow (the repeatable recipe)

1. **Ground TERMS in authoritative sources**, per target language:
   - The language's **GNOME `.po` files** (`l10n.gnome.org`, `gitlab.gnome.org/GNOME/<app>/po/<code>.po`;
     nautilus/gtk/gedit are rich) — authoritative for common UI terms (Open, Files, Folders,
     Search, Preferences, Cut/Copy/Paste, Name/Size/Type…).
   - **National/EU terminology databases** for domain terms the model gets wrong:
     Irish **téarma.ie**, EU **IATE** (all 24 EU official langs), **Microsoft Language Portal**,
     Apple/Google glossaries. (Ex: "regular expression" → téarma authoritative `slonn rialta`;
     Google Translate wrongly gave `abairt rialta`; Gemma gave garbage.)
2. **Pick the model by TIER (below), not one generalist for all.**
3. **Oracle-check** short terms/phrases against an *independent* source (Google Translate,
   glosbe, IATE, or **back-translation** EN→X→EN — if meaning survives it's probably sound).
   Oracles disagree on domain terms → terminology DB wins over MT.
4. **Split by string type:** terms → terminology DB; UI labels → GNOME; **descriptive prose
   (help text, tooltips) → best-available MT, then native review** (prose is where quality
   really breaks and no DB grounds it).
5. **Structural gates** (msgfmt/placeholder/completeness) as the LAST line — necessary,
   never sufficient.
6. **Honest incompleteness:** keep the completeness gate WARN-only until a locale is
   genuinely verified; ship the grounded term/UI layer even if prose awaits native review
   (better than English fallback); **drop** locales no available tool can do faithfully
   rather than force garbage through a hard gate.

## Capability tiers (⚠️ AS OF 2026-07 — re-verify; probe each new locale before trusting it)

Probe a new locale cheaply first: translate its keyword list + 2 UI strings + 1 prose
sentence, then **back-translate** and eyeball. If it comes back anglicized / hallucinated /
non-words → it's Tier 2+.

- **Tier 1 — general LLMs handle well** (high + many mid-resource): en es de fr nl pt it ru
  ar he zh ja ko, and (per Gemma-12B tests) **fa/prs (Persian/Dari), ur (Urdu), am (Amharic),
  km (Khmer)** came back essentially correct. → local Gemma/cloud + review.
- **Tier 2 — general LLMs FABRICATE; need a specialized model / tuned MT + term grounding +
  native prose review:** **ga (Irish), ka (Georgian), ha (Hausa), yo (Yoruba)**, and likely
  most genuinely low-resource languages.
- **Tier 3 — no reliable automated path; native / authoritative source only, or drop:**
  **ie (Interlingue — a *constructed* language, ~no training data), ig (Igbo)**, and the
  rarest. Every LLM (incl. frontier) hallucinates these; do not ship LLM-only.

## Model notes (⚠️ VOLATILE — active research area; verify before relying)

- **General frontier LLMs** (GPT/Claude/Gemini): strong high-resource, **weak low-resource**;
  beaten by specialized systems on Irish (a tuned NLLB was +8 BLEU / +25% over GPT-4).
- **Local generalists** (`gemma4:12b`, `qwen3:8b`): OK mid-resource, **fabricate** low-resource.
  Qwen leaks its `/no_think` control token into output — strip it.
- **Language-specialized LLMs** (worth it for a Tier-2 language you'll invest in):
  - **UCCIX** (`ReliableAI/UCCIX-Llama2-13B-Instruct`) — Irish; **best *translation*** of the
    local options (BLEU EN→GA **0.33**, ~3× Qomhrá). Llama-2-13B → GGUF-convertible for Ollama
    (no ready GGUF; convert yourself). Old base, but the MT winner.
  - **Qomhrá** (`jmcinern/Qomhra`, Qwen3-8B) — Irish; **best Irish *chatbot*** (wins
    Cloze/IQA/grammar) but a **worse translator** (BLEU 0.12). **Lesson: a
    language-specialized *chat* model ≠ a good *translator*; pick by task, verify on MT.**
    Also currently unusable locally (repo ships only config + AWQ, no GGUF/safetensors).
  - Look for equivalents per language (e.g. Latxa/Basque) before assuming a generalist.
- **Dedicated MT** (often best for the *translation* task specifically):
  - **NLLB-200** (+ fine-tunes like adaptMLLM) — best low-resource MT (Irish BLEU ~0.41).
    **Not Ollama-native** (encoder-decoder) → run via CTranslate2/transformers.
  - **Google Translate / EU eTranslation** — decent for EU official languages, **zero-setup**;
    validated our Irish term glossary but **wrong on domain terms** (`abairt rialta`) → override
    with the terminology DB. Good enough as a *prose draft source* for Tier-2 when a local
    specialized model is too much setup.
  - **DeepL** — high-resource only (no Irish, no most low-resource).
- **`translate vs chat`:** for filling `msgstr`, prefer *translation* models / MT over chat
  LLMs; a "best Irish LLM" headline can hide that it's tuned to *converse*, not *translate*.

## The honest ceiling

For genuinely low-resource languages, **no current automated tool reaches native quality
for UI prose.** The realistic completion is "LLM/MT + terminology grounding does ~80%
(terms/UI/diagnostics, verifiable), a human finishes the ~20% descriptive prose." Budget
for a native/community review pass, or accept a documented WARN-incomplete state.

## Keep this updated
This is an **active area of development.** Re-benchmark per language when starting a new
project; update the tiers, model names, and scores; bump `last_verified`. Do not trust a
specific model recommendation here that is more than a few months old.
