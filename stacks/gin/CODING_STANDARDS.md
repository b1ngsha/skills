# Coding Standards

How this service is written where no linter decides. Authors apply every rule
while writing; a review applies every rule to the diff. Each rule carries a
tag:

- **Hard**: a breach is a violation. Cite this file and the section.
- **Judgement**: report it as "possible …" with the reason, and let the author
  decide.

## Owned elsewhere

These documents own their topic. Apply them as written.

| Topic | Owner |
| --- | --- |
| Go tests | `docs/standards/go-testing.md` |

Formatting (`gofmt`) and every rule enabled in `.golangci.yml` belong to the
tools. `make fmt`, `make lint`, and `make test` run them.

## Placement and extraction

The leading word is **colocate**: code sits beside its only caller until a
second owner needs it.

**Hard.**

- A helper starts unexported, in the file or package of its first caller. It
  moves outward one step at a time (file, then package, then a shared
  package) when a caller in the next scope needs it.
- A package is named for what it provides. Shared code joins a package with
  that kind of name.
- One business rule (a validation, a state transition, a limit) has one
  source. A second copy of the same rule is extracted now. A one-line
  expression that already says what its name would say stays at the call
  site.

**Judgement.**

- Look-alike code that encodes different rules stays duplicated until the
  third occurrence that changes for the same reason. Two similar hunks are
  not yet a pattern.
- An abstraction that has grown a boolean or mode parameter, or a branch only
  one caller takes, is split back into each caller. Each caller keeps the
  part it uses.
- A function whose parameter list keeps growing splits into simpler functions
  first. An options struct fits when most callers set several options.

**Smell baseline override.** These rules replace the generic Duplicated Code
smell: flag duplication only per the rules above.

## Parsing at boundaries

The leading word is **parse**: a boundary turns loose input into a domain
type once, and code past the boundary trusts the type.

**Hard.**

- HTTP handlers and other edges parse wire input. A stored string is parsed
  where it is read. Past that point code passes the domain type, and the
  legal values live in that one parse function.
- A domain concept with a closed value set or an invariant gets a named type,
  its constants, and one parse function.

**Judgement.** A check repeated past the boundary, on a value the type
already guarantees, means the parse is missing or leaks.

**Smell baseline override.** These rules decide Primitive Obsession: flag it
only for concepts with a closed value set or an invariant.

## Reads and writes

The leading word is **scope-bound**: every lookup carries the scope its
caller is allowed to see.

**Hard.**

- A lookup that is allowed to see only part of the data passes that scope
  into the query. A lookup by a bare identifier returns a row the caller may
  not own.
- Uniqueness is decided by a unique constraint. The insert is the check, so
  concurrent writers cannot both pass it. The empty result of a conflict
  insert becomes the already-exists outcome.
- A write a client may retry is idempotent, keyed by a natural or
  client-supplied key. A repeat of the same request returns the existing
  result. A different request on the same key is a conflict.

## Errors

The leading word is **handle once**: each error is returned, or logged, or
recovered from. Exactly one.

**Hard.**

- Code below the process edge returns errors. Logging happens at a boundary
  (see Logging).
- A wrap adds what the caller lacks: `fmt.Errorf("<verb> <noun>: %w", err)`,
  starting lowercase. The verb names the operation, so the message reads as
  a path of operations.
- Code branches on `errors.Is` and `errors.As` against sentinels and error
  types. `Error()` text is for humans.
- Names: exported sentinels `ErrXxx`, unexported `errXxx`, error types
  `XxxError`.
- The package that understands a failure translates it there. Callers above
  that package see the translated sentinel or wrapped error.
- `panic` is reserved for programmer misuse caught at construction. Runtime
  and input failures return errors.
- `os.Exit` is called only in `cmd/*/main.go`.

**Judgement.** Use `%w` when a caller up the stack inspects the cause. Use
`%v` at a boundary where the cause's type should stop.

## Outbound calls

**Hard.**

- Every outbound call is bounded in time: the client sets a timeout, or the
  call runs under a `ctx` deadline. The call passes the caller's `ctx`.
- A client makes one attempt. Retry policy belongs to the caller, the only
  one that knows whether the operation is idempotent.
- A retry loop retries an idempotent operation, on an error that reports it
  can be retried, with capped exponential backoff and jitter.

## Logging

The leading word is **boundary**: the HTTP edge, job runners, and `cmd/` log.
Code inside the service returns errors and leaves logging to that edge.

**Hard.**

- A component that logs receives its logger from its constructor.
- The message is a fixed phrase. Varying data goes into structured fields
  with `snake_case` keys.
- An error field carries the error value.
- Fields hold identifiers. Passwords, tokens, session values, keys, and
  connection strings stay out of every field and message.
- Metric attributes come from closed sets: the method, the route template,
  the status code. Identifiers, raw paths, and user input go to traces and
  logs.

**Judgement.** Levels:

| Level | Meaning |
| --- | --- |
| Error | A person needs to act. |
| Warn | The process degraded and handled it itself. |
| Info | Lifecycle and request or job completion. |
| Debug | Diagnostic detail, off in deployed environments. |

## Time, context, and goroutines

**Hard.**

- A decision on the current time (expiry, freshness, revocation) reads an
  injected clock, so a test can set the time. Recorded timestamps come from
  the store.
- `context.Context` is the first parameter of anything that does I/O. The
  function uses the context it was given.
- A goroutine has an owner that stops it and waits for it.
- `init` stays free of I/O and global state.

## HTTP

Gin is the HTTP router.

**Hard.**

- Handlers parse the request, call into the service with typed values, and
  write the status. The service does not import Gin.
- `GET /healthz` is liveness and responds `204` when the process can serve.

**Judgement.** A metric or log that records a request uses the route
template, the pattern registered on the router, rather than the raw path.
