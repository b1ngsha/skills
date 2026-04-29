---
name: refactor-entropy-cleanup
description: Reorganizes and splits files in a target directory to reduce entropy accumulated from multi-round AI-generated code. Reads each file's content to identify mixed responsibilities, misplaced modules, oversized files, and naming drift, then proposes and applies a directory layout that follows community-accepted standards for the detected stack (React/Vue/Node/Python/Go/Java/etc.). Use when the user asks to clean up, reorganize, restructure, refactor a directory, fix module boundaries, split bloated files, reduce code entropy, or normalize a project layout that has become messy after many AI iterations.
---

# Refactor Entropy Cleanup

Multi-round Agent edits typically inflate files (mixed responsibilities), scatter related logic, and drift from naming/layering conventions. This skill performs a **content-aware** reorganization — not just file moves, but intra-file splits — and aligns the result with community-accepted standards for the detected stack.

## Hard Rules

1. **Never** start moving/splitting before the Discovery → Plan → Confirm cycle completes.
2. **Never** change runtime behavior. This is a pure refactor: same public APIs, same exports, same side effects.
3. **Never** introduce a new layer/abstraction that the existing codebase does not already justify (no speculative DDD, no premature `core/domain/` split for a 20-file project).
4. **Always** read full file content for every file in scope before proposing splits — names lie, content tells the truth.
5. **Always** keep changes reversible: one logical move/split per commit-equivalent step.
6. **Do not split by implementation variant alone.** If two implementations share the same business meaning (for example, two providers for the same evaluator), prefer one cohesive module with provider-specific factories unless SDK contracts or file size justify separation.

## Workflow

Copy this checklist into TodoWrite and track progress:

```
- [ ] 1. Scope & stack detection
- [ ] 2. Inventory: read every file in scope
- [ ] 3. Detect entropy signals
- [ ] 4. Pick target layout (consult standards.md)
- [ ] 5. Produce migration plan (moves + intra-file splits + import rewrites)
- [ ] 6. Confirm plan with user
- [ ] 7. Execute in safe order
- [ ] 8. Verify (typecheck/lint/tests/imports)
```

### 1. Scope & stack detection

Ask the user for the target directory if not given. Then detect:

- **Language/stack**: `package.json` (React/Vue/Next/Node), `pyproject.toml`/`requirements.txt` (Django/FastAPI/Flask), `go.mod`, `pom.xml`/`build.gradle`, `Cargo.toml`.
- **Existing convention signals**: presence of `src/features/`, `src/components/`, `app/`, `pages/`, `internal/`, `cmd/`, `apps/<name>/domain/`, `tests/` layout, etc.
- **Style config**: ESLint/Prettier/Ruff/golangci-lint configs reveal naming rules — respect them.

Record findings before any plan. Standards differ sharply by stack; consult [standards.md](standards.md).

### 2. Inventory: read every file in scope

For **each** file:

- Read full content (no skimming).
- Record: primary responsibility, secondary responsibilities, exports, imports, LOC, side effects (top-level execution, singletons), test coverage if visible.

This is non-negotiable. The whole premise of the skill is that file *contents* — not just names — drive the new layout.

### 3. Detect entropy signals

Flag any file or group exhibiting:

| Signal | Example |
|---|---|
| **Mixed responsibilities** | A `utils.ts` containing date formatting + HTTP client + DOM helpers |
| **God file** | Single file >300 LOC with >1 exported concept (component + hook + types + API call) |
| **Layer violation** | UI component importing DB driver directly; route handler containing business rules |
| **Sibling drift** | `userService.ts` and `user-service.ts` and `UserSvc.ts` coexisting |
| **Orphan / dead** | File never imported, or only imported by another orphan |
| **Cross-feature leakage** | `features/billing/` importing from `features/onboarding/internals/` |
| **Type-vs-runtime mix** | Types, constants, and runtime logic crammed in one module |
| **Duplicated logic** | Two near-identical implementations across files |
| **Wrong granularity** | One file per one-line constant; or 12 components in one file |
| **Variant leakage** | `bootstrap.ts` or route setup contains repeated `provider === 'x' ? ... : ...` wiring for multiple subsystems |
| **Provider split drift** | `openai-foo.ts` and `gemini-foo.ts` duplicate schemas/prompts because the real concept is `foo` |

Produce a concrete list with file paths and offending excerpts. Do not propose fixes yet.

### Provider / Variant Boundaries

When entropy comes from multiple providers, adapters, runtimes, or SDK variants:

- Keep the **business concept** as the organizing unit: `rss-evaluator.ts` can own both `createOpenAiRssEvaluator` and `createGeminiRssEvaluator` when both mean "evaluate RSS articles".
- Split provider files only when the integration contract is large or materially different: chat runners that map provider-specific message formats may deserve separate `openai-agent-runner.ts` / `gemini-agent-runner.ts`.
- Centralize provider selection in a narrow composition module when the same choice configures multiple collaborators. Example shape: `llm/runtime.ts` returns `{ agent, rssEvaluator, chatModel }`, while `bootstrap.ts` only consumes that runtime.
- Avoid scattering provider conditionals across setup files. One provider switch is acceptable; repeated switches in the same entry point are a boundary smell.
- Do not introduce a generic registry/plugin system until there are enough providers and runtime behavior to justify it.

### 4. Pick target layout

Open [standards.md](standards.md) and select the layout that:

- Matches the detected stack.
- Matches the **scale** of the project (small project → flat; large → feature-sliced or layered).
- Minimizes deviation from what already exists. **Prefer evolving the current layout over imposing a new one.**

If the user has an `AGENTS.md`, `CONTRIBUTING.md`, or similar, those override standards.md.

For small Node/TypeScript backends, prefer evolving the current responsibility folders. A single narrow composition folder such as `src/llm/runtime.ts` is acceptable when it removes repeated provider wiring, but do not convert the whole project to layered architecture just to host it.

### 5. Migration plan

Produce a single plan document with three sections:

**a. File moves** — old path → new path, one per line.

**b. Intra-file splits** — for each god file, list the new files it becomes and which symbols/lines go where. Example:

```
src/utils.ts (412 LOC) splits into:
  - src/lib/date/format.ts          (formatDate, parseISODate)
  - src/lib/http/client.ts          (apiClient, withAuth)
  - src/lib/dom/scroll.ts           (scrollIntoViewIfNeeded)
  - src/types/user.ts               (User, UserRole — type-only)
```

**c. Import rewrites** — every importer of a moved/split symbol gets updated. Note that re-export barrels (`index.ts`, `__init__.py`, `mod.rs`) may absorb most rewrites.

**d. Composition rewrites** — if variant selection is leaking, list where the branch moves and what simple runtime/factory object it returns. Keep this object narrow and named by the subsystem it composes.

### 6. Confirm with user

Present the plan. Wait for approval. Do not skip this — refactor scope is the #1 source of regret.

### 7. Execute in safe order

Apply changes in this order to keep the tree compilable at every step where possible:

1. Create new directories and empty target files.
2. Move/split content into new files (copy, not delete yet).
3. Update barrel/re-export files to point to new locations.
4. Update all importers.
5. Delete old files only after step 4 succeeds.
6. Remove now-empty directories.

For large refactors, group steps by feature/module so each group is independently verifiable.

### 8. Verify

Run, in order, whatever the project supports:

- Typecheck: `tsc --noEmit`, `mypy`, `pyright`, `go vet`, `cargo check`.
- Lint: project's lint command.
- Tests: project's test command.
- Dead-import scan: `ts-prune`, `unimport`, `ruff --select F401`, etc.
- Manual smoke: open the entry point and trace one user-facing flow.

If any step fails, fix or roll back. Do not declare done with red checks.

## Anti-Patterns (do not do these)

- **Moving without reading.** Renaming a file based on its name is guesswork.
- **Splitting for its own sake.** A 200-line file with one cohesive responsibility is fine. LOC is a signal, not a verdict.
- **Inventing layers.** Don't add `domain/`, `application/`, `infrastructure/` to a CRUD app that has 8 endpoints.
- **Renaming public APIs.** Refactor is internal. Public exports, route paths, CLI flags, env vars stay identical.
- **Mass-renaming style.** Don't switch `camelCase` ↔ `kebab-case` filenames unless the project lint rule already mandates it.
- **Big-bang commits.** Split execution into reviewable chunks, even if delivered in one session.
- **Provider-per-file reflex.** Don't create `openai-x.ts`, `gemini-x.ts`, and `anthropic-x.ts` if the shared concept, schema, and prompt are the same. That duplicates knowledge and creates naming drift.
- **Hardcoded variant scatter.** Don't leave the same provider conditional in bootstrap, services, workers, and commands. Move selection to the smallest composition boundary that can return the already-wired collaborators.

## Output Template

When presenting the plan to the user, use:

```markdown
## Scope
<directories analyzed, file count, total LOC>

## Stack & Convention
<detected stack, existing layout pattern, lint/style rules respected>

## Entropy Findings
<numbered list, each with: file path, signal type, evidence excerpt>

## Proposed Layout
<tree diagram of target structure>

## Migration Plan
### Moves
<old → new>
### Splits
<file → [new files with symbol lists]>
### Import Rewrites
<count + sample>
### Composition Rewrites
<provider/runtime branch moved from X to Y, returned object shape>

## Verification Plan
<commands to run after execution>
```

## Reference

- [standards.md](standards.md) — community-accepted layouts per stack.
