# CSS Convention Rules

## Rule Overview

| Rule ID | Priority | Description                          |
| ------- | -------- | ------------------------------------ |
| css-001 | P1       | Static styles should use Tailwind    |
| css-002 | P1       | Dynamic styles should use `style`    |
| css-003 | P2       | Detect and remove redundant styles   |
| css-004 | P3       | Style organization conventions       |

---

## css-001: Static Styles Should Use Tailwind

**Priority**: P1 (high)

### Description

Fixed, unchanging styles should use Tailwind class names instead of `style` objects.

### Pattern

```tsx
// ❌ problem: static styles in a style object
<Box style={{ flex: 1, backgroundColor: 'white', padding: 16 }}>
<Text style={{ fontSize: 18, fontWeight: '600', color: '#111827' }}>

// ❌ problem: lots of static styles in StyleSheet
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white',
    padding: 16,
  },
});
```

### Recommended Fix

```tsx
// ✅ use Tailwind
<Box className="flex-1 bg-white p-4">
<Text className="text-lg font-semibold text-gray-900">
```

### Exceptions

`style` is fine in these cases:

- Dynamically computed values
- Styles determined by conditionals
- Animated values
- The few properties Tailwind doesn't support

---

## css-002: Dynamic Styles Should Use the `style` Prop

**Priority**: P1 (high)

### Description

Styles that change based on conditions/state/props should be in the `style` prop.

### Pattern

```tsx
// ❌ problem: complex conditional class names
<Box className={`p-4 ${isSelected ? 'bg-primary-500 border-primary-600' : 'bg-gray-100 border-gray-200'} ${isDisabled ? 'opacity-50' : ''}`}>

// ❌ problem: dynamic colors via template strings
<Text className={`text-${status === 'error' ? 'red' : 'green'}-500`}>
```

### Recommended Fix

```tsx
// ✅ static styles in className, dynamic styles in style
<Box
  className="p-4 rounded-lg border"
  style={{
    backgroundColor: isSelected ? '#3B82F6' : '#F3F4F6',
    borderColor: isSelected ? '#2563EB' : '#E5E7EB',
    opacity: isDisabled ? 0.5 : 1,
  }}
>

// ✅ dynamic colors via style
<Text
  className="text-sm font-medium"
  style={{ color: status === 'error' ? '#EF4444' : '#10B981' }}
>
```

### What Counts as Dynamic

These cases must use `style`:

| Scenario              | Example                                              |
| --------------------- | ---------------------------------------------------- |
| Conditional color     | `style={{ color: isError ? 'red' : 'black' }}`       |
| Data-driven dimension | `style={{ width: progress * 100 + '%' }}`            |
| Animated value        | `useAnimatedStyle(() => ({ opacity: value.value }))` |
| Computed positioning  | `style={{ top: index * itemHeight }}`                |

---

## css-003: Detect and Remove Redundant Styles

**Priority**: P2 (medium)

### Description

Remove style classes that have no effect or merely repeat the default value.

### Must-Remove Redundancies

| Redundant Style              | Reason                  |
| ---------------------------- | ----------------------- |
| `flex-row` on `<HStack>`     | HStack is flex-row by default |
| `flex-col` on `<VStack>`     | VStack is flex-col by default |
| `items-stretch`              | flex default            |
| `opacity-100`                | default                 |
| `visible`                    | default                 |
| `static`                     | default positioning     |
| `text-left`                  | LTR default             |
| `bg-transparent`             | default                 |
| `font-normal`                | default                 |
| `m-0` / `p-0` (no inherit)   | default                 |
| `border-0` (no border)       | meaningless             |
| `z-0` (no stacking)          | meaningless             |

### Pattern

```tsx
// ❌ redundant
<VStack className="flex flex-col items-stretch">
<HStack className="flex flex-row">
<Box className="opacity-100 visible static">
<Text className="text-left font-normal bg-transparent">
<Box className="m-0 p-0">
```

### Recommended Fix

```tsx
// ✅ drop redundant, keep meaningful ones
<VStack className="gap-4">
<HStack className="justify-between">
<Box className="p-4 bg-white">
<Text className="text-gray-900">
<Box className="rounded-lg">
```

---

## css-004: Style Organization Conventions

**Priority**: P3 (low)

### Class Order

Recommended order for Tailwind class names:

```tsx
className="
  // 1. Layout: flex, grid, items-*, justify-*
  flex items-center justify-between

  // 2. Sizing: w-*, h-*, min-*, max-*
  w-full h-12

  // 3. Spacing: p-*, m-*, gap-*
  p-4 mt-2 gap-3

  // 4. Border: border-*, rounded-*
  border border-gray-200 rounded-lg

  // 5. Background: bg-*
  bg-white

  // 6. Typography: text-*, font-*, leading-*
  text-lg font-semibold text-gray-900

  // 7. Effects: shadow-*, opacity-*
  shadow-sm
"
```

### Extracting Repeated Styles

When the same set of styles repeats ≥3 times, extract:

```tsx
// ❌ duplicated
<Text className="text-sm text-gray-500 font-medium">Label 1</Text>
<Text className="text-sm text-gray-500 font-medium">Label 2</Text>
<Text className="text-sm text-gray-500 font-medium">Label 3</Text>

// ✅ option 1: variable
const labelClass = "text-sm text-gray-500 font-medium";

// ✅ option 2: wrap in a component
const Label = ({ children }) => (
  <Text className="text-sm text-gray-500 font-medium">{children}</Text>
);
```

---

## Review Output Example

````markdown
## 🔴 CSS Convention Issues (4 issues)

### [css-001] Static styles should use Tailwind

- **File**: `components/Card.tsx:23`
- **Code**:
  ```tsx
  <Box style={{ padding: 16, backgroundColor: '#FFFFFF', borderRadius: 8 }}>
  ```
````

- **Fix**:
  ```tsx
  <Box className="p-4 bg-white rounded-lg">
  ```

### [css-002] Dynamic styles should not use conditional class names

- **File**: `components/Button.tsx:45`
- **Code**:
  ```tsx
  <Pressable className={`px-4 py-2 ${isDisabled ? 'opacity-50 bg-gray-300' : 'bg-blue-500'}`}>
  ```
- **Fix**:
  ```tsx
  <Pressable
    className="px-4 py-2 rounded"
    style={{
      backgroundColor: isDisabled ? '#D1D5DB' : '#3B82F6',
      opacity: isDisabled ? 0.5 : 1
    }}
  >
  ```

### [css-003] Redundant styles

- **File**: `components/List.tsx:12`
- **Code**: `<VStack className="flex flex-col items-stretch gap-2">`
- **Redundant**: `flex`, `flex-col`, `items-stretch` (VStack defaults)
- **Fix**: `<VStack className="gap-2">`

### [css-003] Redundant styles

- **File**: `screens/Home.tsx:67`
- **Code**: `<Text className="text-left font-normal opacity-100">`
- **Redundant**: `text-left`, `font-normal`, `opacity-100` (all defaults)
- **Fix**: `<Text>` (add other styles only if needed)
