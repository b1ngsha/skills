# Context Strategies for Multi-Repo Review

Concrete mechanics to keep architecture review within the context budget. Read the strategies in order — apply only what the current scope requires.

## Budget Math

Rough numbers to plan against:

| Artifact | Token cost (order of magnitude) |
|---|---|
| Directory tree, depth 3 | 200-1k per repo |
| `package.json` + `README.md` | 500-2k per repo |
| Public API surface (routes, exports) | 1-5k per repo |
| Full source of one mid-size repo | 100k-500k |
| Full source of a monorepo | overflows any window |

**Implication**: inventory of 5 repos fits comfortably; raw source of even 1 repo is risky. Always plan around inventory + targeted slices.

---

## Strategy 1: Inventory-First

Always start with these commands. Persist outputs to `architecture-map.md` immediately.

```bash
# Per-repo tree (depth 3, dirs only, hide noise)
tree -L 3 -d -I 'node_modules|.git|dist|build|__pycache__|.venv|target' <repo>

# Manifest harvest
fd -d 2 -e json -e toml -e mod -e xml -e gradle 'package|pyproject|go|pom|build' <repo>

# Top-level docs
fd -d 2 -i 'readme|architecture|agents|contributing' <repo>

# ADRs
fd . <repo>/docs/adr 2>/dev/null
```

Read each found file. Summarize each into 5-10 lines in `architecture-map.md`. **Do not** read source files at this stage.

---

## Strategy 2: Disk-Backed Artifacts

Persist intermediate state. Treat the model's working memory as cache, the workspace as source of truth.

Standard artifact set per review:

| File | Purpose | Updated when |
|---|---|---|
| `architecture-map.md` | Per-repo manifest, modules, public surface | Step 2-3 |
| `dependency-edges.md` | Cross-module / cross-repo edges | Step 3 |
| `findings.md` | Each finding with evidence + options | Step 4-5 |
| `review-report.md` | Final user-facing report | Step 6 |

After each step, drop in-memory details and re-read only the relevant artifact for the next step. This is the single most effective overflow countermeasure.

Format `findings.md` as one record per finding so it can be appended without re-reading:

```markdown
## F-001 [layering][high]
- Repo: billing-service
- Path: src/api/webhooks.py:42-87
- Evidence: `from billing.db.models import Invoice` inside HTTP handler; bypasses InvoiceService
- Impact: business rule for refund eligibility duplicated in 2 places
- Options:
  1. Move logic into InvoiceService.process_webhook (low cost, reversible)
  2. Extract WebhookProcessor with explicit dependency on InvoiceService (medium)
  3. Defer; document as known debt (zero cost)
```

---

## Strategy 3: Subagent Fan-Out

For >=2 repos, dispatch one read-only `explore` subagent per repo. Each returns a small structured payload; parent never holds raw source for >1 repo simultaneously.

### Dispatch template

```
Subagent: explore (readonly, "medium" thoroughness)

Task: Architecture inventory of <repo path>.

Return ONLY this JSON (no prose, no source quotes):

{
  "stack": "<lang/framework>",
  "layers": ["<layer1>", "<layer2>", ...],
  "top_level_modules": [
    {"name": "<dir>", "responsibility": "<one line>", "public_exports": ["<symbol>", ...]}
  ],
  "external_deps": {
    "internal_repos": ["<repo>", ...],
    "services": ["<service or queue>", ...],
    "datastores": ["<db>", ...]
  },
  "public_surface": {
    "http_routes_count": <int>,
    "grpc_services": ["<svc>", ...],
    "queue_topics_consumed": ["<topic>", ...],
    "queue_topics_produced": ["<topic>", ...],
    "cli_commands": ["<cmd>", ...]
  },
  "owners": "<team or unknown>",
  "notable_observations": ["<short observation>", ...]
}

Do not read source files except to confirm a public export. Do not produce more than 200 lines of output.
```

Parent merges the JSON payloads into `architecture-map.md` and drops them.

### When to dispatch a second wave

After step 3, if a cross-repo concern needs investigation (e.g. "does repo-A reach into repo-B internals?"), dispatch one targeted subagent per concerned repo:

```
Subagent: explore (readonly)

Task: In <repo path>, find every import statement that references "<other-repo-package-name>".
Return as a list:
  - <importing file:line>: <full import statement>

Limit: 50 entries. If more exist, return the first 50 plus a count.
```

Parent does the cross-repo correlation; subagents do the local extraction.

---

## Strategy 4: Slice, Don't Load

When a hypothesis points at a specific file, prefer slicing over full reads.

| Goal | Preferred tool | Avoid |
|---|---|---|
| Find imports of X in repo | `Grep "from X"` | Reading every file |
| Confirm a layer violation | `Grep -A3 -B1 "<bad pattern>"` | `Read` of full file |
| Extract function signature | `Grep "^def <name>" -A5` | Reading whole module |
| Verify a config value | `Grep "<key>"` then `Read offset+limit` | Full config dump |

Only `Read` whole files when:

- The file is short (<200 lines).
- A finding is going to be reported and needs accurate line ranges.
- The user explicitly asked for a deep read.

---

## Strategy 5: Defer Evidence Collection

Form findings from inventory + grep first. Only when a finding is going into the report, do the precise read needed to cite line numbers.

This inverts the usual reading flow. Instead of "read code -> form opinion -> write finding", do "form hypothesis from map -> grep to confirm -> draft finding -> read just enough to cite -> finalize".

It cuts source reads by ~5x with no loss in finding quality, because most reads in a "read everything" approach do not produce findings.

---

## Strategy 6: Refuse Silent Truncation

If a needed artifact would not fit the budget, do not produce a partial review. Surface the constraint and ask the user to choose:

```
The current scope (<N> repos, ~<M> LOC) cannot be reviewed in one pass without
truncating findings. Pick one:

A) Narrow the concern set to just <X> and <Y>.
B) Narrow the repo set to the <K> most critical.
C) Accept a two-pass review: pass 1 inventory + cross-cutting findings,
   pass 2 deep-dive on one repo at a time. Each pass is its own session.

Default if no answer: option C.
```

Choosing partial-and-pretend is the failure mode this skill exists to prevent.

---

## Quick Reference: Phase-by-Phase Token Discipline

| Phase | In-context | On disk | Subagents |
|---|---|---|---|
| 1. Scope | user answers only | - | none |
| 2. Inventory | tree + manifests + READMEs | `architecture-map.md` (append) | optional, 1 per repo |
| 3. Map | the map being built | `architecture-map.md`, `dependency-edges.md` | optional |
| 4. Deep-dive | 1 hypothesis + 1 grep slice at a time | `findings.md` (append per finding) | 1 per repo per cross-repo concern |
| 5. Synthesis | `findings.md` only | `findings.md` (sorted + grouped) | none |
| 6. Report | template + `findings.md` | `review-report.md` | none |

If at any phase the in-context column would exceed roughly half the model's window, stop and apply Strategy 6.
