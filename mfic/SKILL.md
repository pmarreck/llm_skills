---
name: mfic
description: Use when designing or judging a test, gate, runtime check, or review process for trustworthiness — especially for code or data produced by an LLM (or a hurried human). Covers making a check non-gameable (Mechanically-Falsifiable Independent Control): picking the strongest test technique, getting genuine independence (external oracle vs a different agent / producer-approver pair), and escalating enforcement from advisory instruction to blocking hook to cryptographic signed commits/actions. Invoke on questions like "can this test be trusted?", "who should write the tests?", "how do we stop the model fabricating or cutting corners?", or when choosing between differential / metamorphic / mutation / property-based testing.
---

# MFIC — Mechanically-Falsifiable Independent Control

A discipline for tests and runtime checks that can't be fooled by the same mistake that produced the code.

**Canonical source of truth:** `~/Documents/MFIC.md` (public gist id `b30aa3ca69cb70a5526f8a63ab8c8d7e`). That file is the full prose + worked examples; **edit it, not this skill, when the discipline evolves**, then refresh the summary below. This skill is the operational digest you apply while working.

## The core idea

Treat the producer of code/data — an LLM, or a hurried human — as an untrusted party in a production process, and place an **independent check at each handoff boundary** that derives its verdict from the *contract or the data itself*, never from the producer's account of it. This is the COSO / Sarbanes-Oxley internal-control model with the LLM as the new untrusted actor. TDD's red phase proves a test *can* fire — that is the **F** alone; MFIC adds the other three axes.

**Litmus (apply this first):** *if the same agent wrote both the check and the thing checked, could it pass with wrong work?* Yes → gameable, not MFIC. No → MFIC.

## The four load-bearing words (drop one, name what leaks in)

- **Mechanically** — cases/oracle machine-swept, not hand-picked. ¬M → omission bugs.
- **Falsifiable** — each case is a biting refutation you can't pre-arrange. ¬F → vacuous always-green tests, or weak oracles ("doesn't crash" hiding wrong output).
- **Independent** — truth source causally independent of the producer (≡ audit **segregation of duties**: maker ≠ checker). ¬I → collusive tests; the axis TDD leaves open.
- **Control** — a baseline to deviate from **plus** authority to fail/halt/steer. ¬C → telemetry that observes but never blocks.

## Pick the strongest technique, cheapest first

finite domain → exhaust it · inverse exists → round-trip `decode(encode(x))==x` · reference impl exists → differential · invariant survives a transform → metamorphic · can corrupt known-good input → mutation/shotgun (yields a *coverage number*, not a bool) · else → property-based + shrink. **Prefer the oracle the author didn't write** — oracle-free (metamorphic, mutation, invariant-from-t0) beats an authored oracle. (Mutation testing needs a paired **specificity corpus** so a reject-everything checker can't score 100%, and a must-detect vs may-ignore split so padding/CRC don't count.)

Two regimes: **static** (verify code in CI — detective) and **dynamic** (verify state in flight in prod — preventive: reject before next step; corrective: bounce back).

## Independence — the axis TDD leaves open

It has **two sources**, and which you need turns on one question: *is there an oracle outside the producer?*

- **External oracle exists** (differential, round-trip, metamorphic, checksum/schema fixed at t0): **authorship is irrelevant to I** — the same agent may write code and check; it still can't make wrong work pass, because the judge is a separate causal entity.
- **No external oracle** (hand-authored expected-values — classic example-based TDD): the author *is* the oracle, so the litmus bites. The **only** remaining source of independence is a **different author** who derives cases from the **contract**, never reading the implementation (a checker that reads the code is anchored → collusion through reading).

**Operationalize without serializing — the producer/approver pair:** the producer writes its own tests red-green and codes against them (supplies **M**/**F**, never idles); an independent approver — ideally a **different model family** — holds *acceptance authority* over a passing test and may interrupt mid-stream (supplies **I**/**C**). The approver runs the litmus on the producer's tests ("do these actually pin the contract, or are they vacuous/collusive?") — a *test of controls*, not a redo.

## Enforcement — the Control axis escalates

Same invariant, escalating rungs, each closing the prior gap:

1. **Instruction (policy)** — a written rule. M-F-I but **¬C**: no power to stop the action; leaks the moment it's ignored.
2. **Blocking gate** — a hook that intercepts and refuses (pre-commit rejecting a stale field; pre-exec blocking a forbidden command). Supplies **C**. Circumventable by whoever controls the gate → **reasonable assurance**: reliably stops the *accidental* violation (the realistic threat), not a determined adversary. Correctly-scoped, not failed.
3. **Cryptographic capability** — the actor *lacks the capability* to proceed alone. An approver signs the exact artifact (commit tree-hash, or a specific command+args) with a private key the producer doesn't hold; a verifier *the producer can't edit* (protected remote / isolated CI) admits only a matching, **fresh** signature. Add freshness — an `approved_at` timestamp with a short max-age, or a single-use nonce — or a "what+who" signature still replays across *when* into a standing grant. Two surfaces: **signed commits** (gate history; naturally fresh) and **signed actions** (gate certain privileged commands before they run; the time-gate matters most here).

Every rung **relocates** trust (to the gate's host, the approver's key, the approver's independence) rather than eliminating it — still reasonable assurance, not proof. Every rung needs a break-glass **override**; since *management override of controls* is the classic weakness, make it **loud and logged** (signed, dated, reasoned, audit-trailed, reviewed) — a silent override is a hole; a conspicuous one preserves the assurance.

## Evidence is constitutive

A control that leaves no trail didn't run. Version measurement history (perf, allocation counts, coverage) by commit + hardware. Statistical members give *reasonable assurance*, not proof — the recognized standard, not a deficiency.
