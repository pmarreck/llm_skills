---
name: gather-project-intentions
description: Establish or clarify project purpose when starting project work without INTENT.md, migrating PROJECT_OVERVIEW.md, resolving unclear or conflicting goals, or documenting a substantial new development direction. Preserve known intent, interview the owner only for material gaps, and keep terminology and execution plans separate.
---

# Gather project intentions

Maintain a concise, agent-neutral account of why the project exists, whom it
serves, and what success means. Use ordinary Markdown and Git; no particular
agent, service, plugin, or interview UI is required.

## Document boundaries

- `INTENT.md`: stable overarching purpose, users, outcomes, scope/non-goals,
  constraints, success evidence and unresolved assumptions. Stable is not
  immutable: substantive changes require the owner's direction or confirmation.
- `TERMINOLOGY.md`: project-specific definitions worth sharing across documents.
  Create it when migrating existing definitions or when a useful glossary exists;
  do not create an empty file or a general computing dictionary.
- `intents/<direction>.md`: optional later development directions with independent
  scope or acceptance criteria. Keep the root's overarching purpose intact.
- `PLAN.md`: current work, sequence, dependencies and progress. Detailed designs
  or specs exist only when needed. `RULES.md` keeps engineering invariants and
  established policy decisions. `README.md` explains the product to its users.

Link to the authoritative home of a fact instead of maintaining competing copies.
Use the exact names above on case-sensitive filesystems. If `intent.md`,
`intent/`, or a different existing convention already exists, inspect it first;
agree a scoped migration rather than creating parallel authorities.

## Establish what is already known

1. Establish the requested repository and mutation scope from the request; ask
   only if unclear. Read its instructions,
   Git status, existing intent/overview, README, rules and relevant plan or spec.
   Use supplied conversation or directly relevant handoff evidence when needed.
   Do not search the whole home directory or unrelated projects for context.
2. Separate owner-stated decisions, agent proposals, current implementation and
   unresolved hypotheses. Code explains what exists, not necessarily what was
   intended. Do not infer product purpose solely from a repository name or code.
3. If the evidence is clear, draft or migrate directly. Do not repeat an
   onboarding questionnaire whose answers are already present. If intent already
   exists and fits the task, read it and proceed without rewriting it.
4. Missing files do not grant new authority. On a read-only request, report the
   gap without creating documents. In a scoped change task, document only the
   project placed in scope; do not launch fleet migrations or change global rules.

## Interview only where it changes the result

Ask one to three focused, plain-text questions at a time, grounded in the gaps.
Examples: who needs this and what cannot they do today; what observable outcome
would make it useful; what is explicitly excluded; which conflicting goal wins.
Explain a tradeoff when the answer materially changes the design.

Preserve the owner's language where it carries meaning. Do not invent personas,
business models, deadlines, obligations, or approval. Mark unanswered questions
and hypotheses as unresolved. If a conflict would change the project's purpose
or erase an existing boundary, preserve both accounts and ask before resolving
it. Safe unrelated work may continue; do not implement the disputed choice.

For an authorized setup with too little evidence, a short explicitly provisional
`INTENT.md` may preserve known facts and unanswered questions. Otherwise wait for
answers. Neither approach establishes accepted purpose before the owner answers.

## Migrate without losing information

Before changing `PROJECT_OVERVIEW.md`, inspect whether it is a regular file or
symlink and check both tracked and uncommitted content. Do not edit an external
symlink target as an accidental side effect. Require a recoverable Git version
or an explicit backup of the exact content being migrated, including local edits.
Keep backups outside the active document tree using the established recovery
location; report that location. Do not commit backups by default, especially
when they may contain private material.

Read the whole overview and map each useful part:

- Purpose, audience, outcomes and product boundaries go to `INTENT.md`.
- Definitions go to `TERMINOLOGY.md`.
- Progress and next actions go to the existing `PLAN.md`; durable architecture
  details or policy go to an appropriate existing document, with a link.

If destinations already exist, reconcile them, never overwrite them blindly.
Surface contradictions rather than silently preferring the newer filename.
Preserve implementation-status facts without turning them into eternal intent.
Remove redundant text only after confirming that its meaning survives elsewhere.

Update active in-repo links and instructions referencing the old filename.
Historical records can retain it as historical context. Retire the overview only
after the migration is complete and recoverable; do not leave an authoritative
duplicate or add a compatibility symlink by default. While a material question
is unanswered, retain the original and mark the migration incomplete.

## Write only the structure the project needs

A useful root outline is: purpose/users; desired outcomes; scope and non-goals;
constraints/tradeoffs; how success is verified; open questions; links to glossary,
plan and relevant directions. Omit empty sections. Distinguish desired behavior
from measured capability. Cite existing acceptance tests or specifications rather
than copying their full contents. Identify the source of consequential decisions;
use Git for revision history instead of a manually maintained timestamp on every
paragraph. Record actual approvals only when they were given.

Do not create `intents/` for routine fixes or each checkbox. Add a direction when
it has its own meaningful outcome, boundaries or unresolved product decision.
Include its relation to root intent, status (proposed/accepted/completed or the
project's existing vocabulary), scope, success criteria and source of approval
if accepted. Link it from the root or plan without loading every direction into
every session. Completed direction records can preserve rationale without
remaining on the active work list. No recursive hierarchy is required.

An existing long `INTENT.md` may mix overarching purpose with independent
directions. Extract only those directions, preserve stable identifiers/links
where they exist, and leave the root as a concise index and overarching intent.
Splitting documents must not silently accept a proposal or change its scope.

## Completion and control

Check the result against the original evidence: no lost constraints or terms,
invented claims, unresolved contradictions hidden as decisions, broken references,
or duplicate sources of truth. Update existing project instructions or their
canonical source only within the authorized scope; do not create new `AGENTS.md`
or `CLAUDE.md` files merely to satisfy this workflow. A shared instruction already
pointing agents to `INTENT.md` is sufficient. When creating or installing this
skill, verify the intended agent discovery paths can read it; ordinary project
migrations need no machine-wide skill-installation audit.

Intent is a contract for verification, not evidence that implementation succeeds
and not authorization for deployment or other privileged actions. Do not weaken
accepted outcomes to make the current code pass. Propose an intent revision
separately and preserve the accepted baseline until the owner resolves it.
An agent-written approval label is not an independent control; use the existing
project review and test gates, without introducing new automation unasked.

Report what migrated, where the old content is recoverable, unresolved questions
and which files changed. Run the relevant existing checks before committing.

## Background

Adapted from the intent/spec/plan distinction in
[Anthropic's AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook).
The root-plus-optional-directions convention here is a local workflow choice,
not a claim of a universal schema or automatic filename discovery by every agent.
