# Quick Checklist

Run through this list quickly during a review. See `rules/` for full details.

## Preparation

- [ ] Read `frontend/package.json` for dependencies and scripts
- [ ] Read `frontend/app.json` for app config
- [ ] Read `frontend/tsconfig.json` for TS config

## 🔴 Critical Checks (must pass)

### TypeScript Type Safety

- [ ] No `any`
- [ ] All component Props have type definitions
- [ ] No non-null assertion `!`
- [ ] Use `import type` for type imports

### Memory Safety

- [ ] Every `useEffect` has cleanup (subscriptions / timers / listeners)
- [ ] `setTimeout`/`setInterval` cleared on unmount
- [ ] Event listeners removed on unmount
- [ ] Reanimated animations properly cancelled

## 🟡 High-Impact Checks (strongly recommended)

### Performance

- [ ] `FlatList` uses `keyExtractor`
- [ ] `FlatList`'s `renderItem` uses `useCallback`
- [ ] Expensive computations use `useMemo`
- [ ] Pure components use `memo`
- [ ] Use `expo-image` instead of RN `Image`
- [ ] No inline style objects

### Cross-Platform

- [ ] Use `SafeAreaView` or `useSafeAreaInsets`
- [ ] Touch targets ≥ 44×44pt (or use `hitSlop`)
- [ ] Use flex and `useWindowDimensions` for responsive layout
- [ ] `KeyboardAvoidingView` differentiates platform behavior

## 🟢 Medium-Impact Checks (recommended)

### RN Conventions

- [ ] Use `Pressable` instead of `TouchableOpacity`
- [ ] Use Expo SDK modules
- [ ] Hook dependency arrays complete
- [ ] Use `react-query` for data fetching

### UI Conventions

- [ ] Prefer Gluestack components
- [ ] Use theme tokens (colors / spacing / typography)
- [ ] Interactive elements have accessibility attributes
- [ ] Use `Button` for buttons with backgrounds; `Pressable` for small icon-only buttons

## Verification

```bash
cd frontend
npm run lint          # ESLint
npx tsc --noEmit      # type check
```

## Quick Search Commands

```bash
# search for any types
rg ":\s*any\b" frontend/ --type ts

# search for uncleaned effects
rg "useEffect" frontend/ -A 8 | grep -B 6 "^\s*\},"

# search for FlatList without keyExtractor
rg "<FlatList" frontend/ -A 5 | grep -v "keyExtractor"

# search for hard-coded colors
rg "#[0-9a-fA-F]{3,6}" frontend/ --type tsx

# search for TouchableOpacity
rg "TouchableOpacity" frontend/
```
