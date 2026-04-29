---
name: useless-code-cleanup
description: Removes useless code and useless comments from a target file or directory without changing behavior. Targets three patterns - (1) meaningless fallbacks (defensive `||`/`??`/try-catch guarding failure modes that cannot occur), (2) premature extractions that violate the Rule of Three (helpers pulled out on the 2nd occurrence, or extractions whose call sites only coincidentally share shape rather than logical meaning), (3) obvious comments that just restate what the next line of code literally says. Use when the user asks to clean useless/dead/redundant/noise code, strip pointless comments, remove cruft, simplify defensive code, inline a wrong abstraction, "清理无用代码", "删冗余", "去无用注释", "清理 fallback", or "撤销过早抽取".
---

# Useless Code Cleanup

Strips three kinds of noise from a codebase without changing behavior:

1. Meaningless fallbacks
2. Premature / wrong extractions (violates Rule of Three)
3. Obvious comments

This is a **subtractive** refactor. Behavior in / behavior out is identical.

> Sibling skill: `refactor-entropy-cleanup` reorganizes files and modules. This one cleans the *content* of a file: defensive noise, wrong abstractions, redundant prose. Use them in sequence if both apply (entropy cleanup first, then this).

---

## Hard Rules

1. **Never change runtime behavior.** Same outputs, same errors, same side effects. If unsure whether a fallback can fire, treat it as live until proven dead.
2. **Discover → Mark → Confirm → Delete.** Never delete on first pass. Build a complete list, get user approval (unless trivially safe), then act.
3. **One pattern per pass.** Don't mix fallback removal with extraction inlining in the same diff. Easier to review and revert.
4. **Read full file content** for every file in scope before judging. `git blame` and call-site count beat intuition.
5. **Burden of proof is on deletion.** Each removed line needs a one-sentence rationale. If you can't write the rationale, keep the line.
6. **Tests, types, lint must still pass** after each pattern's pass.

---

## Scope

Ask the user for the target if not given:

- Single file
- Single directory (recursive)
- A diff range (e.g. cleanup what *this PR* added)

Exclude by default: generated code, vendored code, migrations, lockfiles, snapshot test fixtures.

---

## Workflow

Copy this checklist into TodoWrite:

```
- [ ] 1. Confirm scope (files/dirs, exclusions)
- [ ] 2. Read every in-scope file fully
- [ ] 3. Pass A: scan for meaningless fallbacks → build list
- [ ] 4. Pass B: scan for premature extractions → build list
- [ ] 5. Pass C: scan for obvious comments → build list
- [ ] 6. Present consolidated findings to user
- [ ] 7. Apply Pass A deletions, run checks
- [ ] 8. Apply Pass B inlines, run checks
- [ ] 9. Apply Pass C deletions, run checks
- [ ] 10. Final report
```

Run typecheck + lint + tests after each apply step. Stop and rollback that pass if anything regresses.

---

## Pattern 1 — Meaningless Fallbacks

### What counts as meaningless

A fallback is **meaningless** when no realistic execution path can reach the fallback branch. Common shapes:

- `value ?? defaultValue` where `value` has a non-nullable type and no upstream returns null.
- `try { ... } catch { /* ignore */ }` swallowing errors that the surrounding code cannot recover from anyway (the caller has no signal anything failed).
- `if (!param) return` at the top of a function whose only callers always pass a truthy value, where TypeScript / type system already enforces non-null.
- Re-validating data that was just validated upstream by the same module.
- `else { /* unreachable */ }` branches after an exhaustive if-chain.
- Defensive copies / clones of immutable data.
- "Just in case" null checks on object properties that the constructor guarantees.

### Decision rule

For each candidate, ask:

> *What concrete failure mode does this guard against, and can I write a test that triggers it?*

- Can name one with a runnable example → **keep**.
- Cannot → **delete**.
- Unsure → **keep, add a one-line comment explaining the assumed failure mode** (turning silent defense into documented intent).

### Always keep

- Fallbacks at trust boundaries: user input, network responses, file IO, third-party SDK return values, env vars, deserialized JSON.
- Catch blocks that translate / re-throw with context (they *do* have an effect even if logging only).
- Defaults for genuinely optional config.

### Examples

Bad — non-null TS field, the `??` can never fire:

```ts
interface User { id: string; name: string }
function greet(u: User) {
  return `Hi ${u.name ?? "anonymous"}`;
}
```

Good:

```ts
function greet(u: User) {
  return `Hi ${u.name}`;
}
```

Bad — silent swallow with no recovery:

```ts
try {
  cache.set(key, value);
} catch {}
```

Good — either let it throw, or document why swallowing is correct:

```ts
// Cache is best-effort; failures must not break the request path.
try { cache.set(key, value); } catch (e) { logger.warn("cache.set failed", e); }
```

---

## Pattern 2 — Premature / Wrong Extraction (Rule of Three)

### The rule

> First time: write the logic inline.
> Second time: copy-paste.
> Third time: *then* consider extracting.

The Rule of Three is not about line count — it's about **statistical evidence that the abstraction is real**. With only one or two call sites, you cannot tell whether the shared shape is *meaning* or *coincidence*.

### The discriminator

When considering extraction (or judging an existing extracted helper):

> *Do all call sites share the same **logical meaning**, or do they merely share **syntactic shape**?*

- Same meaning → extract is correct.
- Merely similar code → **do not extract** (or **inline** if already extracted). Coincidental similarity creates a fragile coupling: the next requirement change forces a flag/parameter to fork behavior, and the helper becomes a pile of `if (mode === ...)` branches.

### Detection signals (look for these)

| Signal | What it usually means |
|---|---|
| Helper called from only 1 site | Extracted too early; inline it. |
| Helper called from 2 sites, both inside the same module | Inline-back candidate. |
| Helper called from 3+ sites, but each call passes different flags/booleans to alter behavior | Wrong abstraction (coincidental). Split it. |
| Generic name (`process`, `handle`, `formatItem`, `doStuff`, `helper`) | Often a sign the extractor couldn't name the shared meaning — because there isn't one. |
| Parameter list grew over time (3 → 5 → 8 params) | Each new caller forced a knob; signals coincidental shape. |
| Helper has a `mode` / `type` / `variant` / `isFoo` boolean parameter | Almost always two unrelated things glued together. |
| Body is a `switch (kind) { ... }` over the variant param | Confirmed: it's two functions wearing one name. |

### Decision tree

1. Count call sites of the helper (`rg`/Grep).
2. If **< 3 sites** → inline back to call sites. Stop.
3. If **≥ 3 sites**:
   - Read each call site. Describe in one sentence what *that* call site is conceptually doing.
   - If the sentences are the same → extraction is real, keep.
   - If sentences differ → split the helper per meaning, inline shared bits if any.

### Always keep

- Helpers that wrap an external API call, even with one caller (separation of integration boundary).
- Pure utilities with stable, well-known semantics (`clamp`, `debounce`, `chunk`) — these are "extracted" by being part of the standard library, not the rule-of-three test.
- Helpers required by tests for mocking / DI.

### Examples

Bad — extracted on 2nd use, only ever called twice, and the two callers want subtly different things:

```ts
function buildUserLabel(u: User, includeEmail: boolean) {
  return includeEmail ? `${u.name} <${u.email}>` : u.name;
}
// only callers:
buildUserLabel(u, true);   // for header
buildUserLabel(u, false);  // for menu item
```

Good — inline back, the boolean flag is the smoking gun:

```ts
const headerLabel = `${u.name} <${u.email}>`;
const menuLabel = u.name;
```

Bad — 3 callers but coincidental shape (different *meaning*):

```ts
function format(value: unknown, kind: "currency" | "date" | "percent") {
  switch (kind) {
    case "currency": return `$${(value as number).toFixed(2)}`;
    case "date":     return new Date(value as string).toLocaleDateString();
    case "percent":  return `${(value as number) * 100}%`;
  }
}
```

Good — split per meaning:

```ts
const formatCurrency = (n: number) => `$${n.toFixed(2)}`;
const formatDate     = (s: string) => new Date(s).toLocaleDateString();
const formatPercent  = (n: number) => `${n * 100}%`;
```

---

## Pattern 3 — Obvious Comments

### What counts as obvious

A comment that adds zero information beyond what the code on the next line already states:

- `// Import the module` above an `import` line.
- `// Define the function` above `function foo() {`.
- `// Increment the counter` above `counter++`.
- `// Return the result` above `return result`.
- `// Loop over items` above a `for` loop.
- `// Handle the error` above a `catch`.
- Block comments that recite parameter names already visible in the signature.
- Auto-generated JSDoc with no description text (`@param x x`).
- Commented-out code (use git history instead).
- Stale TODOs whose task is already done in this same file.

### Keep comments that explain

- **WHY** — intent, trade-off, business rule, constraint.
- Non-obvious side effects or ordering requirements.
- References: ticket IDs, RFCs, GitHub issues, security advisories, paper / spec links.
- Workarounds for known bugs in dependencies (with link/version).
- Tricky concurrency, race conditions, retry semantics.
- Performance choices that look weird without context.

### Decision rule

For each comment, ask:

> *If I delete this comment, does a competent reader of the next 5 lines lose any information?*

- No → delete.
- Yes → keep.
- Comment is wrong or stale → fix it; don't silently delete.

### Examples

Bad:

```ts
// Get the user by id
const user = await getUserById(id);
```

Good — delete the comment.

Bad:

```ts
// Retry up to 3 times
for (let i = 0; i < 3; i++) { ... }
```

Better — explain *why* 3, or delete:

```ts
// Stripe webhooks tolerate up to 3 retries before marking the endpoint unhealthy.
for (let i = 0; i < 3; i++) { ... }
```

---

## Reporting Format

Before applying anything, present a single consolidated report:

```
Pattern 1 — Meaningless Fallbacks (N candidates)
  src/foo.ts:42   `?? "anonymous"` on non-null `User.name`     → delete
  src/bar.ts:88   try/catch swallows cache.set                 → keep + add log

Pattern 2 — Premature Extractions (M candidates)
  src/format.ts   `format(value, kind)` — 3 callers, coincidental shape → split
  src/label.ts    `buildUserLabel` — 2 callers, boolean flag             → inline

Pattern 3 — Obvious Comments (K candidates)
  src/foo.ts:10   "// import the module"                       → delete
  src/foo.ts:55   "// retry up to 3 times"                     → keep, clarify why
```

Then ask the user to approve, narrow, or veto specific items.

---

## Anti-Patterns to Avoid

- **Bulk deletion without rationale.** Every line removed must have a written reason. "Looks unused" is not a reason — verify with grep / call analysis.
- **Stripping fallbacks at IO boundaries** (network, file, env, user input, JSON parse). Always live, always keep.
- **Inlining a helper that exists for testability or DI**, even with one caller.
- **Deleting comments that reference tickets / CVEs / RFCs**, even if they look "redundant".
- **Mixing patterns in one diff.** Always one pass per pattern.
- **Renaming or restructuring** during this skill. That belongs to a separate refactor; this skill only deletes / inlines.
- **Removing logs** that look like dead defense — logs are observability, not fallbacks.
- **Over-eager rule-of-three application** — the rule is about *judgment*, not a mechanical "fewer than 3 callers → delete". Stable, well-named utilities can live with 1 caller.
