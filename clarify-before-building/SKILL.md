---
name: clarify-before-building
description: Resolve materially underspecified change requests before implementation, recover existing decisions, ask focused questions, and preserve acceptance criteria. Use when competing interpretations affect scope, user-visible behavior, cost, data safety, or how success is verified. Do not turn clear small edits, exploratory discussion, or read-only investigation into a requirements ceremony.
---

# Clarify before building

Help the owner make consequential choices before investing in the wrong result.
This is an interview and handoff procedure, not a new development framework.
Plain conversation and existing project documents suffice across agents.

## First decide whether a question is needed now

Read the request, applicable instructions, and the relevant existing intent,
specification or decision record. Check available evidence before asking the
owner to repeat it. Distinguish an unknown product choice from a technical fact
you can establish through a scoped inspection or experiment.

- **Clear, bounded request:** proceed using the existing test discipline. A
  typo fix does not need an interview, a new spec file or renewed approval.
- **Material ambiguity:** name the competing interpretations and the concrete
  consequence of choosing incorrectly. Ask before implementing that choice.
- **Reversible, low-impact detail:** state a reasonable assumption and proceed
  within scope. Do not seek approval for every implementation decision.
- **Exploration only:** investigate and label proposals; do not silently turn
  discussion into implementation or deployment.

If another task is active, a new request normally joins its queue. Record the
new request and its unresolved decision in the existing plan (use `planning-work`
for its format). You may propose postponing the interview until a named natural
checkpoint: “I can ask about retention after the current fix passes its tests;
I've queued it.” Continue the current work unless the owner changes priority.
Revisit the queued questions at that checkpoint; include them in a handoff if
the session ends first. Do not forget the request or build the ambiguous branch
while calling it postponed. An emergency or a decision blocking current work
needs immediate attention instead.

## Ask questions that distinguish outcomes

Ask one to three focused questions per round, in ordinary language. Include a
recommendation and its tradeoff where useful, without steering the owner toward
an unstated goal. Prefer one concrete example or counterexample over “please
provide more detail.” Stop when the next bounded increment is specified enough.

Select only missing, consequential questions from these areas:

- What should the person using this be able to accomplish? What observable
  result would count as done? Which tempting adjacent feature is excluded?
- What happens on failure, cancellation or partial completion? Which existing
  behavior, data or interface must remain intact?
- What scale or resource limit matters, and how will we measure it? Convert
  “fast” or “secure” into a specific requirement rather than inventing numbers.
- Which approved constraint takes precedence when two requests conflict?

For example, “clean up the cache” could mean report reclaimable space or delete
files. Establish which before deletion; inspect actual cache ownership yourself.
“Make the scan faster” needs a workload and baseline, not a guessed thread count.

Call out the gap directly and respectfully: “This leaves X undefined; A and B
would produce different behavior. I recommend A because Y. Which do you want?”
Challenge the premise with evidence when appropriate. Confidence, urgency and
familiarity are not answers to an unresolved question. Do not diagnose the
owner's mental state, shame them, or treat a short message as incompetence.
Use owner-specific collaboration preferences when available.

## Preserve decisions without multiplying documents

Summarize the agreed outcome, non-goals, important constraints, acceptance
examples and remaining assumptions before substantial implementation. Existing
explicit answers need no ritual second approval. Keep material unanswered
choices visibly open; silence or “use your judgment” does not settle a conflict
with an existing requirement or grant unrelated authority.

Use the existing authoritative feature spec or issue. `gather-project-intentions`
owns stable project purpose and `INTENT.md`; it need not run for every feature.
`PLAN.md` holds the next actions and links to the decisions, not interview
transcripts. A small change may need only the request and a regression test.
For a durable decision, preserve its rationale and source so the next agent
does not have to re-interview the owner. Do not add a second competing spec.

## Check the work against the agreed behavior

Apply existing TDD and `mfic` practices. Derive meaningful boundary, negative
and failure cases from the accepted behavior, not merely from today's output.
Where trust matters, check against an independent oracle or invariant. Tests
written from the same mistaken assumption can agree with incorrect code.

Link important acceptance criteria to actual checks and report which were run,
failed, skipped or remain untested. Passing a finite suite is evidence about
its covered cases, not proof of complete correctness or security. Do not weaken
an expectation or rewrite accepted intent merely to make the implementation pass.
If a specification appears wrong, surface the counterexample and resolve the
decision separately. Continue safe unrelated work while that choice is pending.

## Evidence and limits

Read [references/evidence.md](references/evidence.md) when explaining the
research basis or changing this procedure. It separates empirical findings,
existing engineering practice and owner-requested interview preferences from
the paper's untested governance proposal. Do not import its case-study effect
sizes, mandatory regeneration, or architectural machinery as established rules.
Use [references/scenarios.md](references/scenarios.md) for maintenance review;
these are decision checks, not evidence that an agent follows the procedure.
