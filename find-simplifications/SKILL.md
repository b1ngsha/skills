---
name: find-simplifications
description: Survey a repository for evidence-backed simplification candidates — dead, duplicated, speculative, over-built, self-verifying, or hand-rolled-where-a-dependency-exists surfaces, plus comments and docs that restate the code — and write each up as an implementable proposal or inline TODO. Use when the user asks what can be simplified, removed, or deleted from a codebase, wants simplification ideas from another branch or PR folded in, or asks to retire design records that a shipped simplification superseded.
---

# Finding Simplifications

Turn a broad "find things to simplify" request into evidence-backed proposals that remove or collapse existing surface area. Follow the code rather than a checklist, and prefer a few well-proven candidates over a pile of thin guesses.

## Start With Repo Context

Before judging any code, read what the repo says about itself: agent instructions (`AGENTS.md`, `CLAUDE.md`), contributor and architecture docs, and any decision records (ADRs, design notes, RFCs). Designs these documents mark as intentional are protected by default: a candidate that collapses one must beat the recorded rationale, not just restate the cost. Removing an unused method inside a protected seam can still be valid when it does not collapse the protected design.

## What Counts As A Strong Candidate

A strong candidate removes, folds, or demotes something real, with evidence that the current design costs more than it buys:

- A public method, event, config knob, helper, module, or package has no production consumer.
- Tests or docs are the only consumers, and the behavior they pin is not load-bearing.
- Two representations mirror the same fact — persisted state duplicating in-memory events, parallel catalogs, mirrored flags.
- A seam has methods every implementation must support but no consumer uses.
- A separate package or module exists only for test/demo/support code and adds publish or dependency overhead.
- A feature implements speculative generality with no owner: plugin registries with one plugin, multi-X support in a single-X product, live invalidation nothing triggers, abstraction layers with a single implementation.
- An invariant, rollback path, or special-case test exists only to protect an unused API.
- Hand-rolled code reimplements what a well-maintained dependency or the standard library already provides, and the swap would delete the implementation plus its dedicated tests.
- The simplified behavior differs slightly from today's, but is still reasonable and easier to explain.

Thin candidates do not earn a proposal: a lone typo, one run of a dead-code tool, deleting a documented intentional design, or "this looks complex" without call-site proof.

### Audit self-verifying checks

A runtime invariant, consistency checker, or health probe earns its place only when it compares independently produced observations that can diverge — distinct event producers, durable history against live state, independently mutable data. Remove checks that inspect mere presence or static metadata, replay a fixed example, or verify the result of the same mutation they claim to verify. Take the export, build entry, check-only dependency, and check-only tests with it, and record why the check was dropped where the next maintainer will look.

## Survey Broadly

Derive survey domains from the repo itself — entry points, the core loop or pipeline, public API and protocol layers, persistence, integrations, packages/tests/scripts. When the user asks for breadth or many candidates, give each domain to a parallel subagent and require evidence, not guesses; without subagents, walk the same domains yourself. Run the survey to completion: a strong early candidate is a data point, not a finish line. Weight the survey toward the files carrying the most production code — an audit that stops at obvious unused symbols misses the files where duplicated lifecycle or defensive machinery carries most of the cost.

## Simplify Prose With The Code

Comments and documentation are maintained surface area; survey them alongside the code they describe.

- Delete comments that restate the code or narrate behavior owned elsewhere. Keep the local contract a reader cannot recover from the code — the why, the invariant, the gotcha.
- Keep each doc at its owning level. Implementation details and rare cases leave unless they change a maintained contract.

## Audit Trust And Lifecycle Boundaries

For every defensive copy, freeze, validator, and callback capture, name where the value came from and who owns it next. Same-process typed calls ordinarily borrow readonly values; parsers, config loaders, queues, external JSON, durable files, workers, and wire decoders own or validate their data. Tests built around hostile getters, fake typed objects, or mutation after a same-process handoff are evidence of a speculative contract, not automatic justification for keeping it.

For complex asynchronous code, draw the ownership graph: map each sentinel, readiness promise, cancellation path, disposer, and state flag to a distinct owner or transition. When several mechanisms mirror the same liveness or settlement fact, propose one lifecycle controller. Preserve separate machinery where it protects synchronous publication and rollback, callback containment, first-terminal-outcome arbitration, worker or process ownership, or dispose-to-quiescence.

## Hand-Rolled Code Versus A Dependency

Introducing a dependency is a valid simplification move. Ask of protocol parsers, framers, retry/backoff loops, glob matchers, diff engines, and similar infrastructure: does a well-maintained package — or the standard library at the version floor the repo already requires — do this? Prove a swap like any other candidate, plus:

- Read the hand-rolled implementation and name the exact surface the package covers; residual semantics the package does not cover count against the swap and stay in the proposal.
- Check the package's health honestly — maintenance, adoption, transitive footprint — and prefer the standard library when it suffices.
- Weigh net deletion: implementation plus dedicated tests plus docs, minus the glue that remains. A wrapper that relocates the same complexity is not a win.

## Prove Or Reject Each Candidate

Classify every consumer before writing anything:

- Production corpus: shipped source, runtime configuration, loader and deployment paths.
- Non-production corpus: tests, docs, comments, snapshots, generated expected outputs.
- Ambiguous corpus: examples and scripts that may be product smoke paths — read their usage before classifying.

Search with `rg` first — the exact symbol, event name, config key, wire strings, and method-name variants — then read the call sites. A dead-code tool can help, but reading is what catches dynamic names, reflection, dependency injection, and config-driven loading.

Reject or downgrade a candidate when:

- A production caller exists, making removal a feature decision rather than a cleanup.
- A recorded decision protects the design and the new evidence does not beat it.
- Removal forces unrelated churn without reducing public API or required behavior.
- The idea is correct but tiny — record an inline TODO instead.

## Write The Proposal

Follow the repo's convention for durable design records when one exists (ADRs, design notes, an issue tracker); otherwise deliver proposals in the survey report. One proposal per candidate; when it overlaps an existing record, consolidate into that record rather than duplicating. Make each proposal concrete enough that an implementing PR can follow the trail:

- **Problem** — the current surface, the files involved, and the consumer evidence, with production callers separated from tests/docs.
- **Proposal** — exactly what to remove, fold, demote, or rehome, including the tests, docs, snapshots, and generated files that go with it.
- **What we give up** — the strongest counterargument, made legible.
- **Acceptance criteria** — the observable end state.
- **Risks** — API changes, behavior changes, plausible future wants, and why the tradeoff still holds.

## Inline TODO Notes

Reserve inline TODO/FIXME for small, local cleanups that are clearly useful but below proposal weight. Name the smell with a stable tag (`TODO(unused-default)`), then say why it is safe to revisit and what action would simplify it. Anything speculative or design-level earns a proposal or nothing.

## Retire Superseded Design Records

When the repo keeps durable design records, a shipped simplification can strand the record that justified the old design. Audit records only when the user asks to reduce them or the change you are implementing makes an owning record obsolete — a code survey does not widen into a repository-wide record audit on its own. Follow [`superseding-records.md`](superseding-records.md) for the supersession test, the added-then-removed case, and the deletion procedure.

## Folding Ideas From Another Branch

Diff the sibling branch against the mainline, not against the current branch, so its independent contribution is visible. Port the non-overlapping items that meet the quality bar, consolidate overlapping material into the record that owns the topic, and keep the reported candidate count honest — duplicates and low-confidence items stay behind. Leave the sibling PR open unless the user asked you to close it or that housekeeping is clearly yours.

## Report The Survey

Close with an accounting the user can check: every domain surveyed or intentionally excluded, every candidate carrying a verdict — proposed, downgraded to a TODO, or rejected with its reason — and, when files were touched, which of the repo's own checks (lint, tests, doc validators) ran clean. When records were retired, name each old and current owner and the evidence for supersession. Keep a PR in draft while the survey is still expanding; mark it ready once the candidate set, review responses, and validation are settled.
