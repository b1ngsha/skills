# React Native Conventions

Priority: **MEDIUM**

## rn-001: Prefer Pressable

### Issue

`TouchableOpacity` and similar legacy APIs are limited; `Pressable` provides more customization.

### ❌ Bad

```tsx
import { TouchableOpacity } from "react-native";

<TouchableOpacity onPress={handlePress}>
  <Text>Tap</Text>
</TouchableOpacity>;
```

### ✅ Good

```tsx
import { Pressable } from "react-native";

<Pressable
  onPress={handlePress}
  style={({ pressed }) => [styles.button, pressed && styles.buttonPressed]}
>
  {({ pressed }) => (
    <Text style={pressed ? styles.textPressed : styles.text}>Tap</Text>
  )}
</Pressable>;
```

---

## rn-002: Use Expo SDK Modules

### Issue

Community packages vary in quality. Expo SDK modules are tested and optimized.

### Recommended Replacements

| Feature        | ❌ Avoid                       | ✅ Prefer              |
| -------------- | ------------------------------ | ---------------------- |
| Image          | `react-native` Image           | `expo-image`           |
| Routing        | `react-navigation`             | `expo-router`          |
| Fonts          | manual loading                 | `expo-font`            |
| Icons          | manual setup                   | `@expo/vector-icons`   |
| Status bar     | RN StatusBar                   | `expo-status-bar`      |
| Linear gradient| `react-native-linear-gradient` | `expo-linear-gradient` |

---

## rn-003: Complete Hook Dependency Arrays

### Issue

Missing deps cause closures to capture stale values.

### ❌ Bad

```tsx
const [count, setCount] = useState(0);

// missing count dep
const handleClick = useCallback(() => {
  console.log(count); // always the initial value
}, []);

// missing userId dep
useEffect(() => {
  fetchUser(userId);
}, []);
```

### ✅ Good

```tsx
const handleClick = useCallback(() => {
  console.log(count);
}, [count]);

useEffect(() => {
  fetchUser(userId);
}, [userId]);
```

### ESLint Config

```js
// eslint.config.js
{
  rules: {
    'react-hooks/exhaustive-deps': 'error',
  }
}
```

---

## rn-004: No Conditional Hook Calls

### Issue

Hooks must be called unconditionally at the top level of the component.

### ❌ Bad

```tsx
const Component = ({ showExtra }) => {
  const [name, setName] = useState("");

  if (showExtra) {
    const [extra, setExtra] = useState(""); // violates Rules of Hooks!
  }

  return <View />;
};
```

### ✅ Good

```tsx
const Component = ({ showExtra }) => {
  const [name, setName] = useState("");
  const [extra, setExtra] = useState("");

  return (
    <View>
      <Text>{name}</Text>
      {showExtra && <Text>{extra}</Text>}
    </View>
  );
};
```

---

## rn-005: Use ref Correctly

### Issue

Wrong ref types cause type errors.

### ✅ Good

```tsx
import type { TextInput, ScrollView } from "react-native";

const inputRef = useRef<TextInput>(null);
const scrollRef = useRef<ScrollView>(null);

// usage
inputRef.current?.focus();
scrollRef.current?.scrollTo({ y: 0 });

// pass to a child
const ChildComponent = forwardRef<TextInput, Props>((props, ref) => {
  return <TextInput ref={ref} {...props} />;
});
```

---

## rn-006: Use ErrorBoundary

### Issue

Uncaught render errors crash the whole app.

### ✅ Good

```tsx
import { ErrorBoundary } from "react-error-boundary";

const ErrorFallback = ({ error, resetErrorBoundary }) => (
  <View style={styles.container}>
    <Text>Something went wrong: {error.message}</Text>
    <Button onPress={resetErrorBoundary} title="Retry" />
  </View>
);

const App = () => (
  <ErrorBoundary FallbackComponent={ErrorFallback}>
    <MainContent />
  </ErrorBoundary>
);
```

---

## rn-007: Form State Management

### Issue

Managing many input states by hand gets messy.

### ✅ Good (with react-hook-form)

```tsx
import { useForm, Controller } from "react-hook-form";

interface FormData {
  email: string;
  password: string;
}

const LoginForm = () => {
  const {
    control,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>();

  const onSubmit = (data: FormData) => {
    // handle submit
  };

  return (
    <VStack space="md">
      <Controller
        control={control}
        name="email"
        rules={{ required: "Email is required" }}
        render={({ field: { onChange, value } }) => (
          <Input>
            <InputField
              value={value}
              onChangeText={onChange}
              placeholder="Email"
            />
          </Input>
        )}
      />
      {errors.email && <Text color="$error">{errors.email.message}</Text>}

      <Button onPress={handleSubmit(onSubmit)}>
        <ButtonText>Sign in</ButtonText>
      </Button>
    </VStack>
  );
};
```

---

## rn-008: Use react-query for Data Fetching

### Issue

Manually managing loading/error/data state is verbose and error-prone.

### ❌ Bad

```tsx
const [data, setData] = useState(null);
const [loading, setLoading] = useState(false);
const [error, setError] = useState(null);

useEffect(() => {
  setLoading(true);
  fetchData()
    .then(setData)
    .catch(setError)
    .finally(() => setLoading(false));
}, []);
```

### ✅ Good

```tsx
import { useQuery } from "@tanstack/react-query";

const { data, isLoading, error, refetch } = useQuery({
  queryKey: ["users", userId],
  queryFn: () => fetchUser(userId),
  staleTime: 5 * 60 * 1000, // 5 minutes
});
```

---

## rn-009: No Side Effects During Render

### Issue

Render functions must be pure. Side effects belong in effects or event handlers.

### ❌ Bad

```tsx
const Component = () => {
  // side effect during render!
  analytics.track("page_view");
  localStorage.setItem("lastVisit", Date.now());

  return <View />;
};
```

### ✅ Good

```tsx
const Component = () => {
  useEffect(() => {
    analytics.track("page_view");
    localStorage.setItem("lastVisit", Date.now());
  }, []);

  return <View />;
};
```

---

## rn-010: Component File Structure

### Recommended Structure

```
components/
├── Button/
│   ├── index.tsx        # exports
│   ├── Button.tsx       # main component
│   ├── Button.types.ts  # type definitions
│   └── Button.test.tsx  # tests
├── Card/
│   └── ...
└── index.ts             # barrel export (use sparingly)
```

### Single-File Component Structure

```tsx
// 1. type definitions
interface Props { ... }

// 2. constants
const ITEM_HEIGHT = 60;

// 3. main component
export const Component = ({ ... }: Props) => {
  // hooks
  // handlers
  // render
};

// 4. subcomponents (if any)
const SubComponent = () => { ... };

// 5. styles (if using StyleSheet)
const styles = StyleSheet.create({ ... });
```
