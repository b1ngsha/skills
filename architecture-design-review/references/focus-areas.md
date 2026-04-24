# Focus Areas: Detection Patterns

Per architectural axis: what to look for, signals that justify reading source, and a minimum-cost detection method. Pick only the axes the user asked for in step 1.

---

## 1. Service Layering

**Model**: a layered architecture has stable directional dependencies (e.g. `route -> service -> repository -> model`). Layers above may call layers below; never the reverse.

### Signals

- Routes/controllers importing ORM models or DB drivers directly (skips service + repository).
- Models importing services (reverse direction).
- Repositories containing business rules (validation, pricing, workflow).
- "Service" classes that only forward to repository methods (anemic — layer is a costume, not a layer).
- A `utils/` or `helpers/` module imported from every layer (hidden god-layer).

### Minimum-cost detection

```bash
# Find route files importing ORM/DB directly (Django example)
rg -l "from .*\.models import|django\.db" --glob '**/views/**' --glob '**/urls/**'

# Find reverse-direction imports
rg "from .*services" --glob '**/models/**'

# Spot anemic services (one-line method bodies that just delegate)
rg -A2 "def \w+\(self.*:$" --glob '**/services/**' | rg -B1 "return self\._?repo"
```

### When to escalate to source read

Only when an import shows a layer skip. Read the offending file, capture the call line, log the finding.

---

## 2. Module Decomposition

**Question**: do modules carve along stable seams (feature, domain, capability) or accidental ones (file type, alphabet, framework convention only)?

### Signals

- Top-level dirs named after framework primitives (`controllers/`, `models/`, `serializers/`) for a project with >50 source files. Indicates layer-by-type, which leaks features across many directories.
- Single feature touching >5 top-level dirs to make any change (high diffusion).
- A `common/` or `shared/` module that grew unboundedly.
- Two modules with near-identical responsibility under different names (`account/` and `user/`).
- Cross-module imports of `internal/`, `_private/`, `__init__`-private symbols.

### Minimum-cost detection

```bash
# Diffusion proxy: which dirs co-change in commits
git log --since="6 months" --name-only --pretty=format: | sort | uniq -c | sort -rn | head -20

# Internal-reach detection (Go convention)
rg -l "/internal/" --glob '!**/internal/**'

# Underscore-prefixed cross-module imports (Python)
rg "from \w+\._\w+ import|import \w+\._" --glob '**/*.py'
```

### When to escalate

When two modules co-change in >50% of commits, read both module roots' top-level docstrings + public exports to judge merge candidate.

---

## 3. Pipeline Design

**Scope**: data ingestion, ETL, event processing, async job chains, request middleware chains.

### Signals

- No clear stage boundary — one function does fetch + transform + validate + persist + notify.
- Retries without idempotency key (silent duplicate writes on failure).
- Error handling that swallows exceptions and returns `None` / empty list (downstream cannot distinguish empty from failure).
- No backpressure — unbounded queue, unlimited concurrency, fixed-size thread pool fed by unbounded source.
- Stage boundaries cross process/network without an explicit contract (no schema, no versioning).
- Stateful stages keyed on in-memory dict (will not survive restart, will not scale horizontally).
- Mixed sync + async in the same chain without explicit boundary, causing event-loop blocking.

### Minimum-cost detection

```bash
# Bare except blocks in pipeline code (Python)
rg "except:|except Exception:\s*$|except Exception as \w+:\s*pass" --glob '**/tasks/**' --glob '**/pipelines/**'

# Retry without idempotency
rg -A5 "retry|@shared_task.*retry|@retry" --glob '**/tasks/**' | rg -v "idempot|dedup"

# Unbounded queues
rg "Queue\(\)|asyncio\.Queue\(\)" --glob '**/*.py'
```

### When to escalate

When a stage handles money, billing, notifications, or external side effects — read the full handler. Pipeline correctness bugs are silent and expensive.

---

## 4. Dependency Direction

**Goal**: a directed acyclic dependency graph at the module level. Cycles are the #1 architecture smell.

### Signals

- Module A imports B which imports A (direct cycle).
- A imports B, B imports C, C imports A (indirect cycle).
- Lateral imports between sibling features (`features/billing/` importing from `features/onboarding/`).
- Domain layer importing infrastructure (DB, HTTP client) directly instead of via interface/port.

### Minimum-cost detection

Per stack:

```bash
# Python
pipx run pydeps <pkg> --max-bacon 0 --no-show --noise-level 0 -o deps.svg
# Or simpler: import-linter (configured in pyproject)

# JS/TS
npx madge --circular --extensions ts,tsx,js,jsx src/

# Go
go mod graph | tsort  # exits non-zero on cycle

# Multi-repo: build the inter-repo edge list manually in architecture-map.md
```

### When to escalate

When a cycle is detected, read only the two import statements that close the cycle, plus the symbol that crosses. Do not read whole files.

---

## 5. Boundary Integrity (encapsulation)

**Question**: are module/repo boundaries respected, or do consumers reach into internals?

### Signals

- Imports of paths containing `internal/`, `_internal`, `private/`, `__private__`.
- Cross-repo imports of non-published symbols (any path that is not the documented public entry point).
- Tests that monkey-patch internals of another module to make a test pass — usually means the public surface is wrong, not the test.
- A "shared" package that re-exports private symbols from N feature modules (turns boundaries into vapor).

### Minimum-cost detection

```bash
# Cross-feature internal reach
rg "from features/\w+/internal" --glob '**/features/**'

# Cross-repo internal reach (monorepo, JS)
rg "from '@org/\w+/dist/internal" --glob '**/*.{ts,tsx,js,jsx}'
```

---

## 6. Data Ownership

**Question**: for every persistent record, which service/module owns writes? Are there shadow writers?

### Signals

- Two services writing to the same table without coordination.
- A service reading another service's DB directly (bypasses the owning API).
- "Sync jobs" that copy data between stores without a documented authoritative source.
- Schema migrations applied from multiple repos to the same database.

### Minimum-cost detection

```bash
# DB connection strings or ORM Meta.db_table per repo
rg "db_table\s*=|connection_url|DATABASE_URL" --glob '**/*.py' --glob '**/*.env*'

# Cross-repo: collect "writes to table X" per repo via subagent, merge, look for >1 owner
```

This axis almost always requires the multi-repo subagent fan-out from `context-strategies.md`.

---

## 7. Observability Seams

**Question**: when something breaks in production, can someone trace it without code-archeology?

### Signals

- Error logs without correlation/trace IDs.
- Pipelines without per-stage metrics (no way to find the slow stage).
- Async jobs without structured failure recording (only `print` to stdout).
- Distributed traces stop at service boundary because trace context is not propagated.

### Minimum-cost detection

```bash
# Logging surface check
rg "logger\.|logging\." --glob '**/*.py' | head -20  # sample style
rg "trace_id|correlation_id|x-request-id" --glob '**/middleware/**'
```

This axis is often "good enough" findings, not blockers — unless the system is already in incident.

---

## 8. Deployment Topology

**Question**: what is the unit of scaling, the unit of failure, and the unit of deploy? Do they line up with module boundaries?

### Signals

- Module boundary inside a single deployable that is the actual scaling bottleneck (cannot scale independently).
- One deployable doing both latency-sensitive (HTTP) and latency-insensitive (batch) work, sized for the worse case.
- Database shared between deployables with very different write patterns (one fast, one slow, one bursty).
- "Microservices" that always deploy together (distributed monolith).

### Minimum-cost detection

Read deployment manifests only:

```bash
fd -e yaml -e yml . k8s/ helm/ deploy/ infrastructure/
fd Dockerfile
fd docker-compose
```

Cross-reference with the module list in `architecture-map.md` — flag mismatches.

---

## Selection Heuristic

If the user said "general health", run these in order until time/budget is exhausted:

1. Dependency direction (cycles)
2. Service layering
3. Boundary integrity
4. Module decomposition
5. Pipeline design (only if pipelines exist)
6. Data ownership (only if multi-repo / multi-service)
7. Deployment topology (only if production state matters)
8. Observability seams (only if incidents are recent)

Stop when the report has 5-15 substantive findings. More than that is unactionable.
