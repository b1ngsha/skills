# Web Testing Standard

A behaviour is asserted once, at the layer that owns it. A component test
renders what the user sees. A route test proves the URL mounted that
component. When another test already fails on the same bug, delete this copy.

## Stack

- Runner: Vitest (`pnpm test`).
- Environment: jsdom for component tests. `src/test/setup.ts` calls Testing
  Library `cleanup()` in `afterEach`. Vitest globals stay off, so that call
  is what unmounts the tree.
- Render and queries: React Testing Library. Clicks and typing go through
  `@testing-library/user-event`.

Move a component test to Vitest Browser Mode when jsdom cannot see the bug:
a layout failure, or a browser API the test would otherwise stub. Give that
file a `.browser.test.tsx` suffix. Keep the query style below so the move
changes `render` and the wait API. End-to-end Playwright is a separate
decision and is not how component tests run.

## File placement

**Hard.**

- A component with its own interaction or state gets a colocated
  `Name.test.tsx`.
- A route with a loader, redirect, or error gets a sibling `-route.test.tsx`.
  The `-` prefix keeps the route generator from treating the test as a route.
- Feature internals stay next to the file they verify.

## Queries

**Hard.**

- Tests locate elements with `getByRole`, `getByLabelText`, or `getByText`,
  and the `find*` / `query*` variants. An async render waits with `findBy*`
  or `waitFor`.

**Judgement.** `querySelector` and `container.textContent` assert structure
the user does not use. Prefer a role or label in a new test.
