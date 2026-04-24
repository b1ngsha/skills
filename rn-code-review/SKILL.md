---
name: rn-code-review
description: React Native + Expo + TypeScript code review. Two modes - PR-level batch review and single-file deep review. Use when reviewing PRs, checking RN best practices, performance, TypeScript type safety, iOS/Android cross-platform compatibility, Gluestack-UI conventions. Triggered by "review", "code review", "check code", "PR review", "review this file", "review this PR", "RN review", or any mention of React Native code quality.
---

# React Native Code Review

Comprehensive code review guide for Expo + React Native + TypeScript + Gluestack-UI v3 projects. Contains 40+ rules across 6 categories.

> **Gluestack v3**: uses "Copy-Paste" model. Components are imported from `@/components/ui` instead of an npm package.

## Scope

Review only code under `frontend/`. Focus on:

- `.tsx` / `.ts` — React components and TypeScript modules
- Config files: `package.json`, `app.json`, `tsconfig.json`, `metro.config.js`, `tailwind.config.js`, `eas.json`

## Priority Order

Rules are ordered by impact. Check high-impact issues first.

| Priority | Category                  | Impact       | Rule prefix  |
| -------- | ------------------------- | ------------ | ------------ |
| 1        | TypeScript type safety    | **Critical** | `ts-*`       |
| 2        | Memory safety & cleanup   | **Critical** | `memory-*`   |
| 3        | Performance               | High         | `perf-*`     |
| 4        | Cross-platform            | High         | `platform-*` |
| 5        | **Componentization**      | Medium       | `comp-*`     |
| 6        | **CSS conventions**       | Medium       | `css-*`      |
| 7        | React Native conventions  | Medium       | `rn-*`       |
| 8        | Gluestack-UI usage        | Medium       | `ui-*`       |

## Quick Reference

### Critical Issues (must fix)

**TypeScript type safety:**

- No `any`. Use `unknown` + type guards.
- Props must declare an interface. No implicit `any`.
- Use `interface` for object shapes (Props, State, API responses). Use `type` for unions, intersections, utility types.
- Use `?.` and `??` instead of `!` non-null assertion.
- Type-only imports use `import type`.

**Memory safety:**

- `useEffect` must return a cleanup (subscriptions, timers, listeners).
- `setTimeout`/`setInterval` must be cleared on unmount.
- Event listeners must be removed.
- Reanimated animations must be `cancelAnimation`-ed.

### High-Impact Issues (strongly recommended)

**Performance:**

- `FlatList` must provide `keyExtractor`.
- No inline `renderItem` functions; use `useCallback`.
- Memoize expensive computations with `useMemo`.
- Long lists (>50 items) must virtualize.
- Use `expo-image`, not RN `Image`.

**Cross-platform:**

- Use `SafeAreaView` or `useSafeAreaInsets`.
- Touch targets ≥ 44×44pt; small elements use `hitSlop`.
- Use `flex` and `useWindowDimensions` for responsive layout.
- `KeyboardAvoidingView` `behavior` differentiated by platform.

### Medium-Impact Issues (recommended)

**Componentization:**

- Duplicated code (≥2 occurrences) must be extracted into a component.
- A single component's JSX should not exceed 150 lines.
- Components reused across pages go in `components/shared/`.
- Keep Props between 3–7; aggregate into objects when more.
- Order code inside a component as follows, separating each section with a blank line:
  1. **Module-level constants** (outside the component)
  2. **state & refs** — `useState`, `useRef`, third-party hooks (`useSafeAreaInsets`, etc.)
  3. **derived values** — plain computed values, `useMemo`
  4. **callbacks** — `useCallback` (logic that needs a stable reference)
  5. **effects** — `useEffect`
  6. **event handlers** — plain functions (`handleXxx`); simple handlers that don't need `useCallback`
  7. **render helpers** — `renderXxx` helpers
  8. **JSX** — `return ( ... )`
- Component comment conventions:
  - Every exported component must have a JSDoc comment before its declaration with a description and `@param` for each prop.
  - Each piece of processing logic (data transforms, conditionals, side effects) must have a brief comment explaining intent.
  - Each independent layout region in JSX (header, list, footer, modal, etc.) must be marked with `{/* region name */}`.
  - Comments should explain "why", not "what". Don't restate the code.

**CSS conventions:**

- Static styles (not driven by props/state) go in Tailwind CSS (`className`).
- Dynamic styles (values driven by props/state) go in the Style object (`style`), including conditionally toggled colors, sizes, etc.
- Don't toggle classes via ternaries inside `className` (e.g. `active ? 'bg-red' : 'bg-blue'`). Use `style={{ backgroundColor: active ? 'red' : 'blue' }}` instead. (NativeWind v4 has known issues with conditional className merging, hence this convention.)
- Dynamic styles for the same component should be centralized in `style`. Avoid having `className` and `style` both contain styles driven by the same condition.
- When a component has both interactive-state classes (`data-[hover]`/`data-[active]`) and conditional `style`, the inactive-state `style` must pass `undefined`, not a concrete value (e.g. `'transparent'`). Otherwise inline `style` overrides the className and overrides the interactive state. Correct: `style={active ? { backgroundColor: '#FFF' } : undefined}`.
- No redundant styles (e.g. `opacity-100`, `flex-col` on `VStack`).

**React Native conventions:**

- Prefer `Pressable` over `TouchableOpacity`.
- Prefer Expo SDK modules (`expo-image`, `expo-router`).
- Hook dependency arrays must be complete and stable.
- Don't use a ternary when `&&` or `||` works. e.g. `condition ? value : null` → `condition && value`; `value ? value : fallback` → `value || fallback`.

**Gluestack-UI v3 usage:**

- Import from `@/components/ui` (not `@gluestack-ui/themed`).
- Prefer Tailwind `className` for styling.
- Use props for component-specific properties (`size`, `action`).
- Provide `accessibilityRole` and `accessibilityLabel`.
- Use `Button` for buttons with a background color; use `Pressable` for small icon-only buttons.

## Review Modes

### Mode Selection

- User specifies a **single file** (e.g. `@file.tsx review`, `review this file`) → single-file deep review.
- User asks for PR review / batch review → PR-level batch review.

### Mode A: PR-Level Batch Review

```
1. Read configs → package.json, app.json, tsconfig.json
2. Get changes → git diff or PR diff
3. Check by priority → Critical → High → Medium
4. Output report → issue list + fix suggestions
```

### Mode B: Single-File Deep Review

**Review philosophy: every line of code must justify its existence.** Be surgical — code that's written but does nothing is the least acceptable. Improving readability counts as "useful", but it must be a real improvement, not self-deceiving "convention".

Single-file review is not just about looking at one file. You have **a global perspective**: is this component's abstraction reasonable? Is its responsibility boundary clear within the project? Is there a better split or merge?

```
1. Read full file content
2. Read direct dependencies (imported custom components/hooks/types) for context
3. If component: read its consumers (who imports it) to assess abstraction
4. Line-by-line deep analysis (see checklist below)
5. Output single-file review report
```

#### Single-File Deep Checklist (in addition to standard rules)

**Logical correctness (bug detection):**

- Closure traps: state/props referenced in callbacks/effects may be stale.
- Race conditions: async operations (fetch, setTimeout) may race or fire repeatedly.
- Conditional branches: do `if/else` and `switch` cover every case? Any missing edge cases?
- Null/boundary: array out-of-bounds, `.find()` returning `undefined` not handled.
- Dependency arrays: are `useEffect`/`useCallback`/`useMemo` deps complete and not redundant?

**Redundancy detection (zero tolerance):**

- Dead code: unused variables, functions, imports, type definitions.
- Ineffective styles: CSS classes with no visual effect on the target component (verify against the component's base style).
- Redundant wrappers: unnecessary `View`/`Box`/`VStack`/`HStack` (single child, no styling effect).
- Useless hook: `useCallback` whose consumer isn't `React.memo`-wrapped; `useMemo` for cheap computations.
- Duplicated logic: similar code blocks within the file (≥3 lines duplicated should be extracted).
- Redundant props: passed but never used, or explicit value identical to default.
- Meaningless intermediate variables: assigned then used once, with no readability gain.
- Redundant type annotations: types TypeScript can infer don't need to be declared.

**Data flow tracing:**

- After a state is defined, is it both read and updated? Any write-only state?
- Are all props received from the parent actually used?
- Are event handler arguments passed correctly?

**Architectural soundness (global perspective):**

- Necessity of abstraction: does this component/hook deserve to exist? With only 1 consumer and simple logic, inlining may be better.
- Granularity: over-split (a 10–20-line pure pass-through component) or over-coupled (one file owns multiple responsibilities)?
- Responsibility boundary: does the component mix logic that doesn't belong (e.g. UI component containing business logic, presentational component managing data fetching)?
- Reuse potential: is logic/component in this file also needed elsewhere but hard-coded here?
- Naming and location: do filename and component name accurately reflect responsibility? Is the directory placement reasonable?

## Report Filtering

- Issues already explicitly marked with `TODO` or `FIXME` in the code should not appear in the review report. They are considered already identified and planned by the team.

## Output Format

Output review results **per file**, one section per file. Order files by issue severity (the most/most-severe issues first).

````markdown
# Code Review Report

## Overview

| Category   | Score     | Issues |
| ---------- | --------- | ------ |
| TypeScript | ⭐⭐⭐⭐☆ | 2      |
| Performance| ⭐⭐⭐☆☆  | 3      |

| Total changed files | Files with issues | Files without issues |
| ------------------- | ----------------- | -------------------- |
| 15                  | 8                 | 7                    |

---

## 📄 `app/(tabs)/market/product-window-publish/custom.tsx`

> New file · 1308 lines

### 🔴 Critical

**[css-001] CSS color value typo: double hash `##`**
- **Lines**: L948, L1079
- **Code**: `'border border-[##86909C]'`
- **Impact**: border color won't apply
- **Fix**: change to `border-[#86909C]`

**[ts-001] Closure references stale state**
- **Lines**: L332-L340
- **Code**:
  ```tsx
  const newImages = [...formData.images, ...result.assets.map(...)].slice(0, 10);
  setFormData((prev) => ({ ...prev, images: newImages }));
  ```
- **Impact**: rapid successive image selections may drop already-selected images
- **Fix**: move merge logic into the functional `setFormData` updater

### 🟡 High

**[comp-001] File exceeds 1300 lines, severely over budget**
- **Suggestion**: split into subcomponents + custom hooks (form logic, image picker, toast, etc.)

**[perf-001] Unused constants**
- **Lines**: L66-L72
- **Code**: `COVER_SIZE`, `GRID_CELL_SIZE`, `GRID_GAP`, `GRID_WIDTH` declared but unused

### 🟢 Good Practices
- ✅ KeyboardAvoidingView correctly differentiates platform behavior
- ✅ Timers properly cleared in useEffect cleanup

---

## 📄 `components/market/MarketCardItem.tsx`

> Modified file

### 🟢 Good Practices
- ✅ Uses expo-image instead of RN Image for better performance
- ✅ Provides recyclingKey for list reuse optimization

**No issues** ✨

---

(more files...)

---

## ✅ Files Without Issues

The following files passed review with no required changes:

- `components/SelectablePill.tsx` — clean component, complete Props interface
- `components/ModalSheetHeader.tsx` — full accessibility attributes
- `components/FullWidthDivider.tsx`
- ...
````

### Single-File Section Structure

Each file section contains the following parts (omit if empty):

1. **File heading** `## 📄 \`relative path\`` + status (new/modified/renamed/deleted)
2. **🔴 Critical** — must-fix issues (bugs, type errors, memory leaks, etc.)
3. **🟡 High** — strongly recommended fixes (performance, componentization, duplication, etc.)
4. **🔵 Medium** — recommended improvements (naming, redundant styles, code style, etc.)
5. **🟢 Good Practices** — noteworthy good patterns in this file (brief list)
6. If a file has no issues, output only `**No issues** ✨` and list it under the bottom "Files Without Issues" summary.

### Single Issue Format

```
**[ruleID] Brief issue description**
- **Lines**: L<start>-L<end> (or single line L<line>)
- **Code**: problem snippet (short quote, ≤5 lines)
- **Impact**: one sentence on consequences
- **Fix**: fix (code or text)
```

### Cross-File Issues

If the same issue spans multiple files (e.g. duplicated code, inconsistent patterns), document it in detail in the **first** affected file and reference from the rest:

```
**[comp-002] Duplicated scroll-sync logic with `CategoryModal.tsx`**
- **Related**: see [comp-002] in `CategoryModal.tsx` for details
- **Suggestion**: extract into a `useSectionScrollSync` hook
```

## References

Detailed rules and code examples:

- `references/rules/` — rule files organized by category
  - `ts-*.md` — TypeScript type safety rules
  - `memory-*.md` — memory safety rules
  - `perf-*.md` — performance rules
  - `platform-*.md` — cross-platform rules
  - `componentization.md` — **componentization rules**
  - `css-standards.md` — **CSS convention rules**
  - `rn-*.md` — React Native conventions
  - `ui-*.md` — Gluestack-UI conventions

- `references/examples/` — code examples
  - `good-patterns.md` — recommended patterns
  - `bad-patterns.md` — anti-patterns

- `references/gluestack-usage.md` — detailed Gluestack-UI guide
- `references/review-checklist.md` — full checklist

Find a specific rule:
```bash
grep -l "FlatList" references/rules/
grep -l "any" references/rules/
````
