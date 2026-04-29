# Community-Accepted Layout Standards

Pick the smallest layout that fits. Project size and existing convention matter more than dogma.

---

## React / Next.js / Vue (frontend SPA)

### Small (< ~50 source files): flat by type

```
src/
├── components/        # reusable presentational components
├── pages/ or routes/  # route-level components
├── hooks/             # shared hooks
├── lib/               # framework-agnostic utilities (date, http, dom)
├── api/ or services/  # backend calls
├── types/             # cross-cutting type definitions
├── styles/
└── main.tsx | app.tsx
```

### Medium / Large: feature-sliced

Reference: [Feature-Sliced Design](https://feature-sliced.design/), Bulletproof React.

```
src/
├── app/               # providers, router, global styles
├── pages/ or routes/  # thin route components, compose features
├── features/
│   └── <feature>/
│       ├── components/
│       ├── hooks/
│       ├── api/
│       ├── types.ts
│       └── index.ts   # public API of the feature (barrel)
├── entities/          # domain objects shared across features (User, Order)
├── shared/
│   ├── ui/            # design-system components (Button, Modal)
│   ├── lib/           # utilities
│   ├── api/           # http client, interceptors
│   └── config/
└── main.tsx
```

Rules:
- A feature **never** imports from another feature's internals — only from its `index.ts`.
- `shared/` never imports from `features/`, `entities/`, `pages/`.
- Routes/pages compose features; features compose entities + shared.

### Next.js App Router specifics

- `app/` is for routing only — keep route files thin, delegate to `features/`.
- Co-locate route-private components under `app/<route>/_components/` (underscore prefix excludes from routing).
- Server-only code in files marked `"server-only"` or in `lib/server/`; client-only in `lib/client/`.

---

## Node.js backend (Express / Fastify / NestJS)

### Small TypeScript backend: flat by responsibility

For small bots, webhook services, CLIs, and single-process backends, prefer existing responsibility folders over a full controller/service/repository stack:

```
src/
├── app.ts or server.ts
├── bootstrap.ts        # app wiring, thin
├── config/ or env.ts
├── <capability>/       # agent, rss, commands, channels, db
│   ├── index.ts        # public API when useful
│   └── *.ts
└── <runtime>/          # narrow composition boundary when one variant choice wires multiple collaborators
```

Rules:
- Keep business concepts grouped by meaning, not provider name. If OpenAI and Gemini both implement RSS article evaluation with the same schema/prompt, one `rss-evaluator.ts` can export both factories.
- Split provider-specific files when SDK contracts dominate the file, e.g. message mapping for `openai-agent-runner.ts` vs `gemini-agent-runner.ts`.
- If provider selection configures multiple collaborators, move the branch to a narrow runtime/composition module and keep `bootstrap.ts` declarative.
- Do not introduce `controllers/`, `services/`, or `repositories/` until routing, business logic, and persistence are actually large enough to need those layers.

### Express/Fastify (medium): layered

```
src/
├── routes/            # HTTP routing only
├── controllers/       # request/response shaping
├── services/          # business logic, framework-agnostic
├── repositories/      # data access (DB, external APIs)
├── models/ or schemas/
├── middleware/
├── lib/               # cross-cutting utilities
├── config/
└── server.ts
```

### NestJS: module-per-feature (framework-mandated)

```
src/
├── <feature>/
│   ├── <feature>.module.ts
│   ├── <feature>.controller.ts
│   ├── <feature>.service.ts
│   ├── dto/
│   └── entities/
├── common/
└── main.ts
```

---

## Python

### FastAPI / Flask (small-to-medium)

```
app/
├── api/               # routers (endpoints only)
│   └── v1/
├── core/              # config, security, lifespan
├── services/          # business logic
├── repositories/ or crud/
├── models/            # ORM models
├── schemas/           # Pydantic models (DTOs)
├── db/                # session, migrations entry
└── main.py
tests/
pyproject.toml
```

### Django: app-per-bounded-context (framework-mandated)

```
project/
├── manage.py
├── config/            # settings, urls, wsgi
└── apps/
    └── <app>/
        ├── models.py | models/
        ├── views.py  | views/
        ├── serializers.py
        ├── urls.py
        ├── services.py    # business logic (not framework-mandated, strongly recommended)
        ├── selectors.py   # read-side queries (HackSoft style)
        └── tests/
```

Reference: [HackSoft Django Styleguide](https://github.com/HackSoftware/Django-Styleguide).

### Library / package

```
src/<package>/
    __init__.py
    <module>.py
tests/
pyproject.toml
```

Use `src/` layout — prevents accidental imports from cwd.

---

## Go

Reference: [golang-standards/project-layout](https://github.com/golang-standards/project-layout) — note this is community convention, **not** official; do not over-apply.

```
.
├── cmd/<binary>/main.go     # one dir per binary
├── internal/                # private packages (compiler-enforced)
│   └── <domain>/
├── pkg/                     # public packages (only if you publish a library)
├── api/                     # protobuf, OpenAPI specs
├── configs/
├── scripts/
└── go.mod
```

Rules:
- Package = directory. Package name = directory name (lowercase, no underscores).
- `internal/` is compiler-enforced privacy. Use it liberally for app code.
- Don't create `pkg/` for an application — only for libraries.
- Avoid `util`, `common`, `helpers` package names — name by responsibility.

---

## Java / Kotlin (Spring Boot)

Package by feature, not by layer:

```
com.company.app/
├── <feature>/
│   ├── <Feature>Controller.java
│   ├── <Feature>Service.java
│   ├── <Feature>Repository.java
│   ├── <Feature>Entity.java
│   └── dto/
├── common/
└── Application.java
```

Avoid the legacy `controller/`, `service/`, `repository/` top-level split for non-trivial apps — it scatters cohesive code.

---

## Rust

```
src/
├── main.rs or lib.rs
├── <module>.rs        # or <module>/mod.rs for multi-file modules
└── <module>/
    ├── mod.rs
    └── <submodule>.rs
tests/                 # integration tests
benches/
examples/
Cargo.toml
```

Rules:
- One concept per module. Re-export public items from `mod.rs` / `lib.rs`.
- Prefer `pub(crate)` over `pub` for internal sharing.

---

## Universal Heuristics (apply across stacks)

1. **Cohesion over LOC.** A 400-line module doing one thing well beats four 100-line modules with tangled imports.
2. **High-cohesion / low-coupling test.** If splitting a file forces every consumer to import from N new places, the split is wrong — provide a barrel or reconsider.
3. **Type-only modules are cheap.** Pulling shared types into `types.ts` / `schemas.py` / a `types` package usually pays off.
4. **Test files mirror source structure.** `src/foo/bar.ts` ↔ `src/foo/bar.test.ts` (co-located) or `tests/foo/bar.test.ts` (parallel tree). Pick one and apply consistently.
5. **Barrel files (`index.ts`, `__init__.py`, `mod.rs`) define the module's public API.** Anything not re-exported is internal.
6. **Naming consistency beats naming correctness.** If the project uses `kebab-case.ts`, new files use `kebab-case.ts` even if you'd personally choose `camelCase`.
7. **Three-strike rule for utilities.** Don't extract a "shared util" until the same logic appears 3 times. Two occurrences may be coincidence.

---

## Detection Cheatsheet

| File | Stack signal |
|---|---|
| `package.json` + `react` dep | React; check for `next`, `vite`, `remix` |
| `package.json` + `vue` dep | Vue; check for `nuxt` |
| `package.json` + `@nestjs/core` | NestJS — use module-per-feature |
| `pyproject.toml` + `fastapi` | FastAPI |
| `manage.py` | Django |
| `go.mod` | Go — check for `cmd/`, `internal/` already |
| `pom.xml` / `build.gradle` + `spring-boot` | Spring Boot |
| `Cargo.toml` | Rust |
