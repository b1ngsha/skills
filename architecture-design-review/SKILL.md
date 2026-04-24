---
name: architecture-design-review
description: Review architecture design quality - service layering, module decomposition, pipeline design, dependency direction, and cross-cutting boundaries. Built for multi-repo scope with strict context-budget controls. Use when the user asks to review an architecture, audit service boundaries, evaluate module split, assess a data or processing pipeline, check layer violations, find coupling or cyclic dependencies, or review system design across one or more repositories.
---

# Architecture Design Review

Audit whether the architecture is sound — layering, module boundaries, pipeline design, dependency direction. Built for **multi-repo scope** with strict context-budget discipline.

## Hard Rules

1. **Never read full source files in the inventory phase.** Inventory uses directory trees, package manifests, READMEs, and public API surface only.
2. **Never load more than one repository's source into context simultaneously** unless a confirmed cross-repo finding is being investigated.
3. **Always persist intermediate artifacts to disk** (`architecture-map.md`, `findings.md`). Each phase must be resumable after dropping context.
4. **Always confirm scope before scanning.** Architecture review without an agreed question produces noise.
5. **Never propose redesigns the team did not ask for.** Output findings + concrete options; the team picks.
6. **Never invent architecture facts.** Every finding cites file path, line range, or a command that reproduces.
7. **Refuse silent truncation.** If scope cannot fit the context budget, say so and ask the user to narrow.

## Workflow

Copy this checklist into TodoWrite and track progress:

```
- [ ] 1. Scope & question framing
- [ ] 2. Repo inventory (no source reads)
- [ ] 3. Build architecture map
- [ ] 4. Targeted deep-dive per concern
- [ ] 5. Findings synthesis
- [ ] 6. Report + options
```

### 1. Scope & question framing

Ask the user once:

- **Repos in scope** — list of paths or repo URLs.
- **Primary concerns** — pick from: layering, module boundaries, pipeline design, dependency cycles, data ownership, deployment topology, or "general health".
- **Risk priority** — correctness > performance > evolvability, or a different ranking.
- **Constraints** — fixed stack, roadmap, headcount, deadline that bound acceptable changes.

Do not start scanning until these are answered. If only one repo is in scope, skip the multi-repo machinery in step 4.

### 2. Repo inventory (no source reads)

Per repo, gather only:

- Directory tree to depth 3 (`Glob` with `**/` patterns or `tree -L 3 -d`).
- Build/package manifests: `package.json`, `pyproject.toml`, `go.mod`, `pom.xml`, `Cargo.toml`, `BUILD`, `Dockerfile`, `docker-compose.yml`.
- Top-level docs: `README.md`, `ARCHITECTURE.md`, `AGENTS.md`, `CONTRIBUTING.md`, ADRs under `docs/adr/`.
- Entry points: `main.*`, `server.*`, `app.*`, route registries, queue task registries.
- Inter-repo coupling: dependency declarations referencing sibling repos, generated SDKs, shared schemas (`*.proto`, OpenAPI specs).

Write a one-screen manifest per repo into `architecture-map.md`. **Do not** open source files in this phase.

### 3. Build architecture map

Append to `architecture-map.md`:

```
## <repo-name>
- Stack: <language/framework>
- Layers detected: <e.g. routes -> services -> repositories -> models>
- Top-level modules: <list with one-line responsibility each>
- External deps: <other repos / services / queues / DBs / 3rd-party APIs>
- Public surface: <HTTP routes count, gRPC services, CLI commands, queue topics>
- Owners: <team or maintainer if known>
```

For multi-repo reviews, append a **dependency edge list**:

```
## Cross-repo edges
- repo-A -> repo-B  (HTTP /v1/users, sync)
- repo-A -> queue:billing-events  (async, fan-out)
- repo-C -> repo-A:internal/utils  (WARNING: reaches into internals)
```

This artifact replaces holding all repos in context. Re-load it on demand instead of re-scanning.

### 4. Targeted deep-dive per concern

For each concern in scope, run a focused pass. Read source **only** when a specific signal warrants it. Detection patterns per axis live in [`references/focus-areas.md`](references/focus-areas.md).

Per concern, follow this loop:

1. Form a hypothesis from the architecture map (e.g. "billing service likely violates layering in webhook handler").
2. Run the minimum search needed to confirm or deny (Grep for the suspect pattern; Read only the matched files).
3. Record the finding with evidence in `findings.md`. Drop the source file from working memory.
4. Move to the next hypothesis.

For multi-repo concerns (cycles, contract drift, leaky internals), use the subagent fan-out pattern in [`references/context-strategies.md`](references/context-strategies.md) — one read-only `explore` subagent per repo, each returning a small structured slice.

### 5. Findings synthesis

Group findings by **axis** and **severity**. Each finding contains:

- **Axis**: layering / modularity / pipeline / dependency / boundary / data-ownership / observability / deployment.
- **Severity**: blocker / high / medium / low.
- **Evidence**: file path(s) with line range, or a command that reproduces.
- **Impact**: one line — what breaks or slows down because of this.
- **Options**: 1-3 concrete responses, each with rough cost and reversibility (do nothing / contain / refactor / re-architect).

Do not collapse distinct findings into a single bullet.

### 6. Report

Use the **Output Template** below. Keep the report body under ~600 lines; link out to `architecture-map.md` and `findings.md` for full detail.

## Context Budget Strategy

Multi-repo architecture review is the canonical context-overflow case. Apply these in order:

1. **Inventory > source.** Tree + manifests + README per repo costs ~1k tokens; reading source costs 100k+. Inventory alone resolves ~70% of architecture findings.
2. **Disk-backed artifacts.** Persist `architecture-map.md`, `dependency-edges.md`, `findings.md`. After each phase, drop in-context details and re-read only the artifact.
3. **Subagent fan-out.** For >=2 independent repos, dispatch one read-only `explore` subagent per repo with a precise extraction prompt ("return module list, public exports, external deps as JSON"). Parent never holds raw source for >1 repo at a time.
4. **Slice, don't load.** When a hypothesis points at a file, prefer `Grep -A/-B` for the matched region over `Read` of the whole file.
5. **Defer evidence collection.** Form the finding first; then read just enough source to cite line numbers.
6. **Refuse silent truncation.** If a needed artifact would not fit, say so explicitly. Ask the user to narrow scope rather than producing a partial review.

Detailed mechanics in [`references/context-strategies.md`](references/context-strategies.md).

## Output Template

```markdown
## Scope
<repos reviewed, concerns in scope, what was explicitly out of scope>

## Architecture Map (summary)
<3-10 line prose summary; full map in architecture-map.md>

## Findings

### Blockers
- **[axis] Title** - evidence: <path:line> - impact: <one line> - options: <a|b|c>

### High
...

### Medium
...

### Low / nits
...

## Options & Trade-offs
<for each non-trivial finding, expand the option set with cost & reversibility>

## Out of Scope / Not Reviewed
<explicit list - what the user should NOT assume was checked>

## Reproducibility
<commands and file paths the user can run to verify findings>
```

## Anti-Patterns

- **Reading every file "to be thorough".** Burns context, produces shallow findings. Map first, read on demand.
- **Single-pass cross-repo dump.** Loading 3 repos at once guarantees truncation and hallucination.
- **Style nitpicks dressed as architecture.** Naming, formatting, lint issues belong in `rn-code-review` / `backend-code-review`, not here.
- **Greenfield redesign proposals.** Stay within the team's actual change budget. Offer the smallest viable fix first.
- **Findings without evidence.** Every claim cites path, line, or command. No "I think the service layer is leaky" without a witness.
- **Hidden evaluation criteria.** State the layering/boundary model you are evaluating against; do not impose one silently.

## Reference

- [`references/focus-areas.md`](references/focus-areas.md) — detection patterns per architectural axis (layering, modularity, pipelines, dependencies, boundaries, data ownership, observability, deployment).
- [`references/context-strategies.md`](references/context-strategies.md) — concrete commands and subagent prompts for keeping multi-repo review within budget.
