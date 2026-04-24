# Cross-Platform Rules

Priority: **HIGH**

## platform-001: Use SafeAreaView or useSafeAreaInsets

### Issue

Hard-coded padding doesn't adapt to varying safe areas (notches, punch holes, etc.).

### ❌ Bad

```tsx
<View style={{ paddingTop: 44 }}>
  <Header />
</View>

<View style={{ paddingBottom: 34 }}>
  <TabBar />
</View>
```

### ✅ Good

```tsx
import { useSafeAreaInsets } from "react-native-safe-area-context";

const Screen = () => {
  const insets = useSafeAreaInsets();

  return (
    <View style={{ paddingTop: insets.top, paddingBottom: insets.bottom }}>
      <Header />
      <Content />
      <TabBar />
    </View>
  );
};

// or use SafeAreaView
import { SafeAreaView } from "react-native-safe-area-context";

const Screen = () => (
  <SafeAreaView style={{ flex: 1 }} edges={["top", "bottom"]}>
    <Content />
  </SafeAreaView>
);
```

---

## platform-002: Touch Target Min 44×44pt

### Issue

Touch targets that are too small are hard to tap, especially on small devices.

### ❌ Bad

```tsx
<Pressable style={{ width: 20, height: 20 }}>
  <Icon name="close" size={16} />
</Pressable>
```

### ✅ Good

```tsx
// option 1: enlarge the actual size
<Pressable style={{ width: 44, height: 44, alignItems: 'center', justifyContent: 'center' }}>
  <Icon name="close" size={16} />
</Pressable>

// option 2: use hitSlop
<Pressable
  style={{ width: 24, height: 24 }}
  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
>
  <Icon name="close" size={16} />
</Pressable>
```

---

## platform-003: Responsive Layout via flex and useWindowDimensions

### Issue

Hard-coded sizes don't adapt to varying screens.

### ❌ Bad

```tsx
<View style={{ width: 375 }}>
  <Image style={{ width: 375, height: 200 }} />
</View>
```

### ✅ Good

```tsx
import { useWindowDimensions } from "react-native";

const Component = () => {
  const { width } = useWindowDimensions();

  return (
    <View style={{ width: "100%" }}>
      <Image style={{ width, height: width * 0.53 }} />
    </View>
  );
};

// or use flex
<View style={{ flex: 1 }}>
  <View style={{ flex: 0.3 }}>Header</View>
  <View style={{ flex: 0.7 }}>Content</View>
</View>;
```

---

## platform-004: KeyboardAvoidingView per Platform

### Issue

iOS and Android handle the keyboard differently.

### ✅ Good

```tsx
import { KeyboardAvoidingView, Platform } from "react-native";

<KeyboardAvoidingView
  style={{ flex: 1 }}
  behavior={Platform.OS === "ios" ? "padding" : "height"}
  keyboardVerticalOffset={Platform.OS === "ios" ? 0 : 20}
>
  <ScrollView>
    <TextInput />
  </ScrollView>
</KeyboardAvoidingView>;
```

---

## platform-005: Use Platform.select for Platform Differences

### Issue

Conditional rendering for platform differences is verbose and error-prone.

### ❌ Bad

```tsx
const styles = StyleSheet.create({
  shadow:
    Platform.OS === "ios"
      ? {
          shadowColor: "#000",
          shadowOffset: { width: 0, height: 2 },
          shadowOpacity: 0.1,
        }
      : { elevation: 2 },
});
```

### ✅ Good

```tsx
const styles = StyleSheet.create({
  shadow: Platform.select({
    ios: {
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.1,
      shadowRadius: 4,
    },
    android: {
      elevation: 2,
    },
    default: {},
  }),
});
```

---

## platform-006: Status Bar Handling

### Issue

Status bar style doesn't match the background color.

### ✅ Good

```tsx
import { StatusBar } from "expo-status-bar";

// at the root or page component
<StatusBar style="dark" backgroundColor="transparent" translucent />;

// dynamic switching
const isDark = useColorScheme() === "dark";
<StatusBar style={isDark ? "light" : "dark"} />;
```

---

## platform-007: Text Overflow Handling

### Issue

Long text without overflow handling breaks layout.

### ✅ Good

```tsx
<Text numberOfLines={2} ellipsizeMode="tail">
  {longText}
</Text>

// auto-shrinking text
<Text adjustsFontSizeToFit numberOfLines={1}>
  {title}
</Text>
```

---

## platform-008: Consider System Font Scaling

### Issue

Users may enable system font scaling, which can break the layout.

### ✅ Good

```tsx
// cap scaling for critical UI
<Text maxFontSizeMultiplier={1.2}>Critical button text</Text>;

// or globally at the root
import { Text } from "react-native";
Text.defaultProps = {
  ...Text.defaultProps,
  maxFontSizeMultiplier: 1.3,
};
```

---

## platform-009: Landscape Mode (if supported)

### Issue

In landscape, safe area and layout need adjustment.

### ✅ Good

```tsx
const { width, height } = useWindowDimensions();
const isLandscape = width > height;

const insets = useSafeAreaInsets();

<View
  style={{
    paddingLeft: isLandscape ? insets.left : 0,
    paddingRight: isLandscape ? insets.right : 0,
  }}
>
  <Content />
</View>;
```

---

## platform-010: Dark Mode Adaptation

### Issue

Without dark-mode adaptation, readability degrades under dark themes.

### ✅ Good

```tsx
import { useColorScheme } from "react-native";

const Component = () => {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";

  return (
    <View style={{ backgroundColor: isDark ? "#1a1a1a" : "#ffffff" }}>
      <Text style={{ color: isDark ? "#ffffff" : "#1a1a1a" }}>Hello</Text>
    </View>
  );
};

// recommended: Gluestack-UI v3 + Tailwind theme colors
import { Box, Text } from "@/components/ui";

<Box className="bg-background-0 dark:bg-background-950">
  <Text className="text-typography-900 dark:text-typography-0">Hello</Text>
</Box>;
```

---

## Test Checklist

- [ ] iPhone SE (small) and iPhone 15 Pro Max (large)
- [ ] Low-end Android (e.g. Pixel 3a) and high-end Android
- [ ] System font scaling: small / default / large
- [ ] Dark mode
- [ ] Landscape (if supported)
- [ ] Different languages (including RTL if applicable)
