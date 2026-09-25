# Evidence boundaries

Reviewed 2026-09-24. This record distinguishes findings from chosen working
conventions. It does not claim this skill has been experimentally validated.

## The supplied paper

Mamdouh Alenezi, [Specification-Driven Development as the Foundation of
AI-Native Enterprise Software Engineering, v1](https://arxiv.org/html/2607.16680v1).
Sections 3 and 8 describe an analytical synthesis, with no new experimental
data. Sections 6.4 and 7.3 identify the headline security and delivery gains as
unreplicated case evidence. Its governance model is a proposal; the hypothesis
that governance explains differing AI-quality outcomes has not been isolated
experimentally. We do not adopt mandatory regeneration, a new layered process,
automatic compliance claims, or numerical benefit promises from it.

## Empirical findings checked at primary sources

| Source | Finding within the studied setting | Limited application here |
|---|---|---|
| Liu et al., [EvalPlus, NeurIPS 2023](https://proceedings.neurips.cc/paper_files/paper/2023/hash/43e9d647ccd3e4b7b5baab53f0368686-Abstract-Conference.html) | Augmenting HumanEval tests exposed previously undetected incorrect generated programs and changed model rankings. | Broaden checks beyond a few passing examples; report coverage limits. It does not establish an optimal interview format or guarantee repository-scale correctness. |
| Perry et al., [Do Users Write More Insecure Code with AI Assistants?, CCS 2023](https://arxiv.org/abs/2211.03622v3) | In security tasks with a codex-davinci-002 assistant, assisted participants produced less secure code overall and were more likely to believe it secure. | Confidence is not security evidence. Use actual security checks. Do not transfer its rates to current models or infer a universal causal benefit from questioning. |
| Borg et al., [Echoes of AI, v3](https://arxiv.org/abs/2507.00788v3) | A two-phase study with 151 participants found no significant downstream completion-time or code-quality differences in its randomized evolution phase. | Retain counter-evidence: AI-assisted code is not established to be inherently unmaintainable. This is bounded evidence, not proof of equivalence or support for compulsory process expansion. |

The primary-source abstracts/proceedings record were checked for these narrow
claims; this is not an independent replication or a full methods audit.

## Basis of the procedure

- Upfront material-gap questions and optional deferral behind an active task
  are an explicit owner-requested collaboration preference (2026-09-24).
  The one-to-three-question grouping is a usability convention, not a measured
  optimum. No claim is made that this paper tested sleep deprivation or proved
  a particular questioning technique mitigates it.
- Recovering existing decisions, preserving scope, keeping one authoritative
  document, TDD and independent controls were already local practices. This
  skill connects those practices to the interview, rather than introducing
  new infrastructure under the paper's authority.
- Tests remain fallible. A deterministic check can repeatedly accept a wrong
  result; an incorrect specification can mislead both producer and checker.
  Independent evidence and explicit assumptions are still necessary.

No new watcher, enforcement hook, agent topology, fleet migration or automatic
rewrite is part of this change. Evaluate the procedure through actual use:
whether it catches a consequential ambiguity, repeats a settled question, delays
a clear task, or fails to return to a queued decision. Correct specific observed
failures instead of claiming an unmeasured productivity improvement.
