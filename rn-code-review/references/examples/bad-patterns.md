# Anti-Patterns

This document lists common bad patterns and what's wrong with them, to help identify code that needs to be fixed.

## 1. Memory Leaks

### ❌ Uncleaned Subscription

```tsx
// problem: subscription survives after unmount
useEffect(() => {
  const subscription = eventEmitter.on("message", handleMessage);
  // missing cleanup!
}, []);

useEffect(() => {
  AppState.addEventListener("change", handleAppState);
  // missing remove!
}, []);
```

### ❌ Uncleaned Timer

```tsx
// problem: timer keeps firing after unmount
useEffect(() => {
  setInterval(() => {
    fetchData();
  }, 5000);
  // never stops
}, []);

const handleClick = () => {
  setTimeout(() => {
    setData(newData); // component may already be unmounted
  }, 1000);
};
```

### ❌ Uncancelled Request

```tsx
// problem: component may have unmounted by the time the request resolves
useEffect(() => {
  fetch("/api/data")
    .then((res) => res.json())
    .then((data) => setData(data)); // Warning: Can't perform state update on unmounted component
}, []);
```

---

## 2. Performance Issues

### ❌ Misuse of FlatList

```tsx
// problem: a new renderItem is created on every render
<FlatList
  data={items}
  renderItem={({ item }) => (
    <View>
      <Text>{item.name}</Text>
      <Button onPress={() => handlePress(item.id)} /> {/* inline function */}
    </View>
  )}
  // missing keyExtractor
/>
```

### ❌ Unnecessary State

```tsx
// problem: filteredItems and count can be derived from items
const [items, setItems] = useState([]);
const [filteredItems, setFilteredItems] = useState([]);
const [count, setCount] = useState(0);

useEffect(() => {
  setFilteredItems(items.filter((i) => i.active));
  setCount(items.length);
}, [items]);
```

### ❌ Inline Style Object

```tsx
// problem: a new object is created on every render
<View style={{ marginTop: 10, padding: 16 }}>
  <Text style={{ fontSize: 14, color: "#333" }}>Hello</Text>
</View>
```

### ❌ Expensive Component Without memo

```tsx
// problem: any parent state change rerenders the child
const ExpensiveChart = ({ data }) => {
  // complex chart rendering
  return <Chart data={data} />;
};

const Parent = () => {
  const [unrelatedState, setUnrelatedState] = useState(0);
  const [chartData] = useState(initialData);

  return (
    <>
      <Button onPress={() => setUnrelatedState((s) => s + 1)} />
      <ExpensiveChart data={chartData} /> {/* rerenders every time */}
    </>
  );
};
```

---

## 3. Type Safety Issues

### ❌ Using any

```tsx
// problem: bypasses type checking
const handleData = (data: any) => {
  return data.user.name; // may crash at runtime
};

const response = await fetch(url);
const json = response.json() as any;
```

### ❌ Missing Props Types

```tsx
// problem: parameters are implicit any
const UserCard = ({ user, onPress }) => {
  return (
    <Pressable onPress={onPress}>
      <Text>{user.name}</Text>
    </Pressable>
  );
};
```

### ❌ Unsafe Type Assertion

```tsx
// problem: at runtime it may not be User
const user = response.data as User;
console.log(user.email); // may be undefined
```

### ❌ Non-null Assertion

```tsx
// problem: may be null/undefined at runtime
const userName = user!.name;
const count = data.items!.length;
```

---

## 4. Cross-Platform Issues

### ❌ Hard-Coded Sizes

```tsx
// problem: doesn't adapt to different screen sizes
<View style={{ width: 375, height: 812 }}>
  <Image style={{ width: 375, height: 200 }} />
</View>
```

### ❌ Hard-Coded Safe Area

```tsx
// problem: safe area differs across devices
<View style={{ paddingTop: 44, paddingBottom: 34 }}>
  <Content />
</View>
```

### ❌ Touch Target Too Small

```tsx
// problem: hard to tap, especially on small screens
<Pressable style={{ width: 20, height: 20 }}>
  <Icon name="close" size={16} />
</Pressable>
```

### ❌ No Keyboard Handling

```tsx
// problem: keyboard covers the input when shown
<View style={{ flex: 1 }}>
  <TextInput />
  <Button title="Submit" />
</View>
```

---

## 5. React Convention Issues

### ❌ Conditional Hook Calls

```tsx
// problem: violates Rules of Hooks
const Component = ({ showExtra }) => {
  const [name, setName] = useState("");

  if (showExtra) {
    const [extra, setExtra] = useState(""); // wrong!
  }

  return <View />;
};
```

### ❌ Side Effects During Render

```tsx
// problem: render function must be pure
const Component = () => {
  analytics.track("page_view"); // wrong! should be in useEffect
  localStorage.setItem("lastVisit", Date.now());

  return <View />;
};
```

### ❌ Stale Closure State

```tsx
// problem: count inside setTimeout is stale
const [count, setCount] = useState(0);

const handleClick = () => {
  setTimeout(() => {
    setCount(count + 1); // count may already be outdated
  }, 1000);
};
```

### ❌ Missing Dependencies

```tsx
// problem: ESLint react-hooks/exhaustive-deps warning
const [userId, setUserId] = useState("1");

useEffect(() => {
  fetchUser(userId); // userId should be in the deps array
}, []);

const handleClick = useCallback(() => {
  console.log(count); // count should be in the deps array
}, []);
```

---

## 6. Gluestack-UI Issues

### ❌ Reinventing Base Components

```tsx
// problem: reinvents the wheel and may miss accessibility features
<TouchableOpacity style={styles.button} onPress={handlePress}>
  <Text style={styles.buttonText}>Confirm</Text>
</TouchableOpacity>;

// use instead (v3 imports from project-local components)
import { Button, ButtonText } from "@/components/ui";

<Button onPress={handlePress}>
  <ButtonText>Confirm</ButtonText>
</Button>;
```

### ❌ Importing from npm Package (v2 way)

```tsx
// problem: v3 no longer imports from the npm package
import { Box, Text } from "@gluestack-ui/themed";

// v3 correct way: import from project-local components
import { Box, Text } from "@/components/ui";
```

### ❌ Hard-Coded Colors and Spacing

```tsx
// problem: doesn't use Tailwind, hard to keep consistent
<View style={{ padding: 16, backgroundColor: "#f5f5f5" }}>
  <Text style={{ fontSize: 14, color: "#333" }}>Title</Text>
</View>;

// v3 should use Tailwind className
import { Box, Text } from "@/components/ui";

<Box className="p-4 bg-background-100">
  <Text className="text-sm text-typography-900">Title</Text>
</Box>;
```

### ❌ Missing Accessibility Attributes

```tsx
// problem: screen-reader users can't use it
<Pressable onPress={handleClose}>
  <Icon name="close" />
</Pressable>

// use instead
<Pressable
  onPress={handleClose}
  accessibilityRole="button"
  accessibilityLabel="Close"
>
  <Icon name="close" />
</Pressable>
```

---

## How to Fix

Each anti-pattern has a corresponding correct pattern. See `good-patterns.md` and the rule files:

- Memory leaks → `memory-safety.md`
- Performance → `perf-optimization.md`
- Types → `ts-type-safety.md`
- Cross-platform → `platform-compatibility.md`
- React conventions → `rn-best-practices.md`
- UI conventions → `ui-gluestack.md`
