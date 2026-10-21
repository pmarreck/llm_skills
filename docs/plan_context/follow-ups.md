# Deferred follow-ups

## Cross-project build-layout adoption

The September 16 skill milestone delivered shared instructions, discovery tests
and a migration reference. Its remaining plan item explicitly reserved dotfiles
migration and a CLI plus bundled GUI pilot for separate implementation scope.
The October 14 inbox reconciliation found no later direct note selecting those
pilots or authorizing their changes. Preserve that boundary; documentation and
installation checks do not establish downstream adoption.

When this work is scoped, recover the target projects' current decisions before
choosing pilots. Verify complete application bundles and operating-system and
architecture selection. A copied binary on the wrong platform remains a useful
failure case for the future migration checks.

## Historical Nix-memory consolidation

The August 19 plan marked the audit complete but said the private root remained
unchanged and a concrete retention/removal proposal still required approval.
The public plan contains no exact proposal or later approval. That is evidence
of an unfinished follow-up, not a current deletion request.

Keep this deferred until a scoped follow-up recovers the original proposal and
reconciles any later decisions. Use the memories skill for that work. Preserve
incident evidence and narrow exceptions; do not infer permission to remove
records from a checked historical task. No private memory root was inspected or
modified during the October 14 planning cleanup.

## October 14 reconciliation

One direct request covered inbox handling, plan organization and a bounded
already-authorized milestone. The legacy processed folder held one July CI
manifest request. Commit `c81f392` already added the flake and target manifest;
`.mechatron-prime/targets` selects `checks.x86_64-linux.test`. No new CI setup
or live webhook change is needed to resolve that old envelope.

The local milestone is the inbox and plan cleanup itself. No additional
implementation milestone is authorized by the remaining historical items.
The initial archive contains 42 completed top-level entries and their nested
notes. It generalizes personal references and private setup details; the
original plan is preserved in Git at `1463a4b`. This cleanup does not rewrite
history or establish that older commits are safe for publication.

Validation completed on October 21 after the interrupted session resumed.
`plan-lint` changed from 199 diagnostics to a clean result. The complete
`build-budget --project llm_skills -- nix develop -c ./test` run exited zero.
The retired July envelope remains recoverable in Trash and Git history.
