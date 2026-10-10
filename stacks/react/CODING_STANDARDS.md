# Coding Standards

How this app is written where no linter decides. Authors apply every rule
while writing; a review applies every rule to the diff. Each rule carries a
tag:

- **Hard**: a breach is a violation. Cite this file and the section.
- **Judgement**: report it as "possible …" with the reason, and let the author
  decide.

## Owned elsewhere

These documents own their topic. Apply them as written.

| Topic | Owner |
| --- | --- |
| Web tests | `docs/standards/web-testing.md` |

Formatting (oxfmt) and every rule enabled in `.oxlintrc.json` belong to the
tools. `pnpm format`, `pnpm lint`, and `pnpm test` run them.

## Placement and extraction

The leading word is **colocate**: code sits beside its only caller until a
second owner needs it.

**Hard.**

- A helper starts unexported, in the file of its first caller. It moves
  outward one step at a time (file, then a shared module) when a caller in
  the next scope needs it.
- A module is named for what it provides. Shared code joins a module with
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
  first. An options object fits when most callers set several options.

**Smell baseline override.** These rules replace the generic Duplicated Code
smell: flag duplication only per the rules above.

## Effects

The leading word is **external system**, as React's
[You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect)
uses it.

**Judgement.**

- `useEffect` synchronizes a component with an external system: a media
  element, a window listener, an observer.
- A value computable from props, state, or query data is computed during
  render. Server data stays in the TanStack Query cache.
- Work a user event causes (open, click, submit) runs in that event's
  handler.

## Routing

TanStack Router owns the URL. TanStack Query owns server data.

**Hard.**

- File routes live under `src/routes/`. The Vite plugin is
  `@tanstack/router-plugin/vite`, registered before the React plugin, with
  `autoCodeSplitting: true`.
- `src/routeTree.gen.ts` is generated and committed. Hand edits to that file
  are discarded. Lint and format ignore it.
- A route file exports `Route` only. A helper that exists for that route
  lives in a sibling file or directory whose name starts with `-`, so the
  generator skips it.
- Path segments are lowercase English `kebab-case`. A collection segment is
  a plural noun. A parameter name says which thing it is (`sceneId`), and is
  camelCase in TypeScript.
- Web URLs stay independent of the API version.
- Each resource has one canonical URL. The path carries a stable id. A
  display name stays out of the path.

**Judgement.** A loader reads what the route needs in order to render. A
mutation that a click causes runs in that click's handler, then invalidates
the query.

## Names and comments

**Hard.**

- When the project has a glossary, identifiers, file names, error messages,
  and log messages use its terms.
- An exported identifier reads well after its module name.

**Judgement.**

- A comment states what the code cannot show: a constraint, a gotcha, or the
  reason for an odd choice. A comment that restates the next line is noise.
- Ticket identifiers belong in the commit, so a comment stays true after the
  review closes.
