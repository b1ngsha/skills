# TypeScript Type Safety Rules

Priority: **CRITICAL**

## ts-001: No `any`

### Issue

`any` bypasses TypeScript's type checks and hides potential bugs.

### Detect

```bash
rg ":\s*any\b" --type ts --type tsx
rg "as\s+any\b" --type ts --type tsx
```

### ❌ Bad

```tsx
const handleData = (data: any) => {
  return data.value; // may crash at runtime
};

const response = await fetch(url);
const json = response.json() as any;
```

### ✅ Good

```tsx
interface DataItem {
  id: string;
  value: number;
}

const handleData = (data: DataItem): number => {
  return data.value;
};

// use unknown + type guard
const json: unknown = await response.json();
if (isDataItem(json)) {
  return json.value;
}

function isDataItem(data: unknown): data is DataItem {
  return (
    typeof data === "object" && data !== null && "id" in data && "value" in data
  );
}
```

---

## ts-002: Props Must Define an Interface

### Issue

Components without Props types fall back to implicit `any`.

### ❌ Bad

```tsx
// implicit any
const Button = ({ onPress, label }) => {
  return (
    <Pressable onPress={onPress}>
      <Text>{label}</Text>
    </Pressable>
  );
};
```

### ✅ Good

```tsx
import type { GestureResponderEvent } from "react-native";

interface ButtonProps {
  onPress: (event: GestureResponderEvent) => void;
  label: string;
  disabled?: boolean;
}

const Button = ({ onPress, label, disabled = false }: ButtonProps) => {
  return (
    <Pressable onPress={onPress} disabled={disabled}>
      <Text>{label}</Text>
    </Pressable>
  );
};
```

---

## ts-003: Use Optional Chaining and Nullish Coalescing

### Issue

`!` non-null assertion is unsafe at runtime. Use `?.` and `??` instead.

### ❌ Bad

```tsx
const userName = user!.name;
const count = data.items!.length;
```

### ✅ Good

```tsx
const userName = user?.name ?? "Unknown";
const count = data?.items?.length ?? 0;
```

---

## ts-004: Type Imports Use `import type`

### Issue

A regular `import` is preserved after compilation and inflates bundle size.

### ❌ Bad

```tsx
import { ViewStyle, TextStyle } from "react-native";
import { User } from "../types";
```

### ✅ Good

```tsx
import type { ViewStyle, TextStyle } from "react-native";
import type { User } from "../types";
```

---

## ts-005: Explicit Return Types on Public Functions

### Issue

Missing return types on public functions can lead to surprises.

### ❌ Bad

```tsx
export const calculateTotal = (items: Item[]) => {
  return items.reduce((sum, item) => sum + item.price, 0);
};
```

### ✅ Good

```tsx
export const calculateTotal = (items: Item[]): number => {
  return items.reduce((sum, item) => sum + item.price, 0);
};
```

---

## ts-006: Generic Parameters Use Meaningful Names

### Issue

Single-letter generics (e.g. `T`) are hard to read.

### ❌ Bad

```tsx
function fetchData<T>(url: string): Promise<T> { ... }
```

### ✅ Good

```tsx
function fetchData<TResponse>(url: string): Promise<TResponse> { ... }

// or more specific
function fetchData<TData extends BaseResponse>(url: string): Promise<TData> { ... }
```

---

## Common React Native Types

```tsx
// event types
import type {
  GestureResponderEvent,
  LayoutChangeEvent,
  NativeSyntheticEvent,
  TextInputChangeEventData,
} from "react-native";

// style types
import type { ViewStyle, TextStyle, ImageStyle } from "react-native";

// Expo Router
import type { Href } from "expo-router";

// ref types
import type { TextInput, ScrollView } from "react-native";
const inputRef = useRef<TextInput>(null);
```
