# Performance Rules

Priority: **HIGH**

## perf-001: FlatList Must Use keyExtractor

### Issue

Without `keyExtractor`, list items can't be reused properly and performance suffers.

### Detect

```bash
rg "<FlatList" --type tsx -A 10 | grep -v "keyExtractor"
```

### ❌ Bad

```tsx
<FlatList data={items} renderItem={({ item }) => <ItemCard item={item} />} />
```

### ✅ Good

```tsx
<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <ItemCard item={item} />}
/>
```

---

## perf-002: Avoid Inline renderItem

### Issue

An inline function creates a new reference every render, causing all list items to rerender.

### ❌ Bad

```tsx
<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => (
    <ItemCard item={item} onPress={() => handlePress(item.id)} />
  )}
/>
```

### ✅ Good

```tsx
const renderItem = useCallback(
  ({ item }: { item: Item }) => <ItemCard item={item} onPress={handlePress} />,
  [handlePress]
);

const handlePress = useCallback((id: string) => {
  // handle press
}, []);

<FlatList data={items} keyExtractor={keyExtractor} renderItem={renderItem} />;

// extract keyExtractor too
const keyExtractor = useCallback((item: Item) => item.id, []);
```

---

## perf-003: FlatList Configuration

### Issue

Default config may be unsuitable for large datasets.

### ✅ Recommended Configuration

```tsx
<FlatList
  data={items}
  keyExtractor={keyExtractor}
  renderItem={renderItem}
  // performance tuning
  initialNumToRender={10} // initial render count
  maxToRenderPerBatch={10} // per-batch render count
  windowSize={5} // render window (in screens)
  removeClippedSubviews={true} // detach offscreen items (Android)
  // when item height is fixed
  getItemLayout={(data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
/>
```

---

## perf-004: useMemo for Expensive Computations

### Issue

Re-running an expensive computation on every render wastes CPU.

### ❌ Bad

```tsx
const Component = ({ items }: Props) => {
  // re-computed every render
  const sortedItems = items.sort((a, b) => b.score - a.score);
  const topItems = sortedItems.slice(0, 10);

  return <List items={topItems} />;
};
```

### ✅ Good

```tsx
const Component = ({ items }: Props) => {
  const topItems = useMemo(() => {
    const sorted = [...items].sort((a, b) => b.score - a.score);
    return sorted.slice(0, 10);
  }, [items]);

  return <List items={topItems} />;
};
```

---

## perf-005: Stable Callbacks via useCallback

### Issue

Unstable callback references cause unnecessary child rerenders.

### ❌ Bad

```tsx
const Parent = () => {
  const handlePress = (id: string) => {
    // new function each render
  };

  return <Child onPress={handlePress} />;
};
```

### ✅ Good

```tsx
const Parent = () => {
  const handlePress = useCallback((id: string) => {
    // stable reference
  }, []);

  return <Child onPress={handlePress} />;
};

// Child should use memo
const Child = memo(({ onPress }: ChildProps) => {
  return <Pressable onPress={onPress}>...</Pressable>;
});
```

---

## perf-006: Use expo-image Instead of Image

### Issue

RN's native `Image` lacks caching and advanced features.

### ❌ Bad

```tsx
import { Image } from "react-native";

<Image source={{ uri: imageUrl }} style={styles.image} />;
```

### ✅ Good

```tsx
import { Image } from "expo-image";

<Image
  source={{ uri: imageUrl }}
  style={styles.image}
  contentFit="cover"
  placeholder={blurhash}
  transition={200}
  cachePolicy="memory-disk"
/>;
```

---

## perf-007: Avoid Creating Objects in Render

### Issue

Inline style objects allocate a new reference each render.

### ❌ Bad

```tsx
<View style={{ marginTop: 10, paddingHorizontal: 16 }}>
  <Text style={{ fontSize: 14, color: "#333" }}>Hello</Text>
</View>
```

### ✅ Good

```tsx
// option 1: StyleSheet
const styles = StyleSheet.create({
  container: { marginTop: 10, paddingHorizontal: 16 },
  text: { fontSize: 14, color: '#333' },
});

<View style={styles.container}>
  <Text style={styles.text}>Hello</Text>
</View>

// option 2: Tailwind/NativeWind (recommended)
<View className="mt-2 px-4">
  <Text className="text-sm text-gray-700">Hello</Text>
</View>
```

---

## perf-008: React.memo for Pure Components

### Issue

Children rerender even when their props haven't changed.

### ✅ Good

```tsx
interface CardProps {
  title: string;
  onPress: () => void;
}

const Card = memo(({ title, onPress }: CardProps) => {
  return (
    <Pressable onPress={onPress}>
      <Text>{title}</Text>
    </Pressable>
  );
});

// custom comparator (optional)
const Card = memo(
  ({ title, onPress }: CardProps) => { ... },
  (prevProps, nextProps) => prevProps.title === nextProps.title
);
```

---

## perf-009: Avoid Unnecessary State

### Issue

Don't store values that can be derived from existing state.

### ❌ Bad

```tsx
const [items, setItems] = useState<Item[]>([]);
const [filteredItems, setFilteredItems] = useState<Item[]>([]);
const [count, setCount] = useState(0);

useEffect(() => {
  setFilteredItems(items.filter((item) => item.active));
  setCount(items.length);
}, [items]);
```

### ✅ Good

```tsx
const [items, setItems] = useState<Item[]>([]);

// derived values are computed directly
const filteredItems = useMemo(
  () => items.filter((item) => item.active),
  [items]
);
const count = items.length;
```

---

## perf-010: Defer Heavy Work with InteractionManager

### Issue

Heavy synchronous work blocks the JS thread and hurts interaction responsiveness.

### ✅ Good

```tsx
useEffect(() => {
  const task = InteractionManager.runAfterInteractions(() => {
    // run after animations/navigation finish
    heavyComputation();
  });

  return () => task.cancel();
}, []);
```
