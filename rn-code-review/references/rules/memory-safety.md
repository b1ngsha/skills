# Memory Safety & Cleanup Rules

Priority: **CRITICAL**

## memory-001: useEffect Must Clean Up Subscriptions

### Issue

Uncleaned subscriptions leak memory and trigger "state update on unmounted component" warnings.

### Detect

```bash
rg "useEffect.*subscribe" --type tsx -A 5 | grep -v "return"
```

### ❌ Bad

```tsx
useEffect(() => {
  const subscription = eventEmitter.subscribe("event", handleEvent);
  // missing cleanup!
}, []);

useEffect(() => {
  const unsubscribe = navigation.addListener("focus", () => {
    fetchData();
  });
  // missing return unsubscribe
}, [navigation]);
```

### ✅ Good

```tsx
useEffect(() => {
  const subscription = eventEmitter.subscribe("event", handleEvent);
  return () => {
    subscription.unsubscribe();
  };
}, []);

useEffect(() => {
  const unsubscribe = navigation.addListener("focus", () => {
    fetchData();
  });
  return unsubscribe;
}, [navigation]);
```

---

## memory-002: Timers Must Be Cleared

### Issue

`setTimeout` and `setInterval` keep firing after unmount unless cleared.

### Detect

```bash
rg "setTimeout|setInterval" --type tsx
```

### ❌ Bad

```tsx
useEffect(() => {
  setTimeout(() => {
    setData(newData); // component may have unmounted
  }, 1000);
}, []);

useEffect(() => {
  setInterval(() => {
    tick();
  }, 1000);
  // never stops!
}, []);
```

### ✅ Good

```tsx
useEffect(() => {
  const timer = setTimeout(() => {
    setData(newData);
  }, 1000);
  return () => clearTimeout(timer);
}, []);

useEffect(() => {
  const interval = setInterval(() => {
    tick();
  }, 1000);
  return () => clearInterval(interval);
}, []);
```

---

## memory-003: Event Listeners Must Be Removed

### Issue

Unremoved event listeners hold memory and may fire multiple times.

### ❌ Bad

```tsx
useEffect(() => {
  Keyboard.addListener("keyboardDidShow", handleKeyboard);
  // missing remove
}, []);

useEffect(() => {
  const subscription = AppState.addEventListener("change", handleAppState);
  // missing cleanup
}, []);
```

### ✅ Good

```tsx
useEffect(() => {
  const subscription = Keyboard.addListener("keyboardDidShow", handleKeyboard);
  return () => {
    subscription.remove();
  };
}, []);

useEffect(() => {
  const subscription = AppState.addEventListener("change", handleAppState);
  return () => {
    subscription.remove();
  };
}, []);
```

---

## memory-004: Reanimated Animations Must Be Cancelled

### Issue

Uncancelled animations keep running after unmount.

### ❌ Bad

```tsx
const translateX = useSharedValue(0);

useEffect(() => {
  translateX.value = withSpring(100);
  // animation may continue after unmount
}, []);
```

### ✅ Good

```tsx
import { cancelAnimation } from "react-native-reanimated";

const translateX = useSharedValue(0);

useEffect(() => {
  translateX.value = withSpring(100);
  return () => {
    cancelAnimation(translateX);
  };
}, []);
```

---

## memory-005: fetch Requests Should Be Cancellable

### Issue

A request that resolves after unmount can cause state-update errors.

### ❌ Bad

```tsx
useEffect(() => {
  fetch(url)
    .then((res) => res.json())
    .then((data) => setData(data)); // component may have unmounted
}, [url]);
```

### ✅ Good

```tsx
useEffect(() => {
  const controller = new AbortController();

  fetch(url, { signal: controller.signal })
    .then((res) => res.json())
    .then((data) => setData(data))
    .catch((err) => {
      if (err.name !== "AbortError") {
        console.error(err);
      }
    });

  return () => {
    controller.abort();
  };
}, [url]);

// or use react-query (recommended)
const { data } = useQuery({
  queryKey: ["data", url],
  queryFn: () => fetch(url).then((res) => res.json()),
});
```

---

## memory-006: Avoid Stale State in Closures

### Issue

Closures inside async operations may capture stale state.

### ❌ Bad

```tsx
const [count, setCount] = useState(0);

const handleClick = () => {
  setTimeout(() => {
    setCount(count + 1); // count may be stale
  }, 1000);
};
```

### ✅ Good

```tsx
const [count, setCount] = useState(0);

const handleClick = () => {
  setTimeout(() => {
    setCount((prev) => prev + 1); // functional update
  }, 1000);
};

// or use a ref to track the latest value
const countRef = useRef(count);
countRef.current = count;

const handleClick = () => {
  setTimeout(() => {
    setCount(countRef.current + 1);
  }, 1000);
};
```
