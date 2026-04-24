# CSS Style Conventions

## Core Principle

**Static styles use Tailwind CSS, dynamic styles use the Style object, and reject redundant styles.**

## Style Decision

```
┌─────────────────────────────────────────────────────────────┐
│                Determine the style type                      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
                  ┌───────────────┐
                  │ Is it dynamic? │
                  └───────────────┘
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
         Yes/dynamic                  No/static
            │                           │
            ▼                           ▼
    ┌──────────────┐            ┌──────────────┐
    │ Style object │            │ Tailwind CSS │
    │ (style prop) │            │  (className) │
    └──────────────┘            └──────────────┘
```

### Definition of Dynamic Styles

The following count as **dynamic** and should use the `style` prop:

1. Styles decided by conditions (if/ternary)
2. Values computed from props/state
3. Animation values that change at runtime
4. Data-driven colors/sizes

### Definition of Static Styles

The following count as **static** and should use `className`:

1. Fixed layout/spacing/colors
2. Responsive breakpoint styles
3. Pseudo-state styles (hover, active, focus)
4. Theme-related fixed styles

## Code Examples

### Correct

```tsx
// Static styles via Tailwind
<Box className="flex-1 bg-white p-4 rounded-lg">
  <Text className="text-lg font-semibold text-gray-900">Title</Text>
</Box>

// Dynamic styles via style
<Box
  className="flex-1 rounded-lg p-4"
  style={{ backgroundColor: isActive ? '#10B981' : '#E5E7EB' }}
>
  <Text
    className="text-lg font-semibold"
    style={{ color: hasError ? '#EF4444' : '#111827' }}
  >
    {title}
  </Text>
</Box>

// Mixed: static via className, dynamic via style
<Pressable
  className="px-4 py-2 rounded-full"
  style={[
    { backgroundColor: variant === 'primary' ? '#3B82F6' : '#F3F4F6' },
    disabled && { opacity: 0.5 }
  ]}
>
  <Text
    className="font-medium"
    style={{ color: variant === 'primary' ? '#FFFFFF' : '#374151' }}
  >
    {label}
  </Text>
</Pressable>
```

### Wrong

```tsx
// Wrong: static styles in style object
<Box style={{ flex: 1, backgroundColor: 'white', padding: 16 }}>

// Wrong: dynamic styles encoded as conditional Tailwind classes (creates many class combinations)
<Box className={`p-4 ${isActive ? 'bg-green-500' : 'bg-gray-200'}`}>

// Wrong: relying entirely on the style object
<Text style={{ fontSize: 18, fontWeight: '600', color: '#111827' }}>
```

## Redundant Style Detection

### Always Remove

The following are browser/RN defaults or have no effect — always delete:

| Redundant Style                | Reason                       | Action |
| ------------------------------ | ---------------------------- | ------ |
| `flex-row` on HStack           | HStack defaults to row       | Remove |
| `flex-col` on VStack           | VStack defaults to column    | Remove |
| `opacity-100`                  | Default value                | Remove |
| `visible`                      | Default value                | Remove |
| `static`                       | Default positioning          | Remove |
| `text-left` in LTR environment | Default value                | Remove |
| `border-0` without a border    | No effect                    | Remove |
| `m-0` or `p-0` without inherit | Default value                | Remove |
| `bg-transparent`               | Default value                | Remove |
| `font-normal`                  | Default value                | Remove |

### Possibly Redundant (judge by context)

| Style           | Redundant When                                          | Action            |
| --------------- | ------------------------------------------------------- | ----------------- |
| `w-full`        | Parent is flex-col and child has no other width limit   | Possibly remove   |
| `items-stretch` | Default value of a flex container                       | Remove            |
| `flex-shrink`   | Default value is 1                                      | Remove `shrink`   |
| `flex-grow-0`   | Default value                                           | Remove            |
| `z-0`           | No stacking-context conflict                            | Remove            |

### Detection Examples

```tsx
// Redundant
<VStack className="flex flex-col items-stretch">  // flex-col and items-stretch are redundant
<HStack className="flex flex-row">                 // flex-row is redundant
<Box className="opacity-100 visible static">       // all defaults
<Text className="text-left font-normal">           // all defaults

// Concise
<VStack className="gap-4">
<HStack className="justify-between">
<Box className="p-4 bg-white">
<Text className="text-gray-900">
```

## Style Organization

### className Order (recommended)

Order Tailwind classes for readability:

```tsx
className="
  // 1. Layout
  flex flex-row items-center justify-between

  // 2. Sizing
  w-full h-12

  // 3. Spacing
  p-4 m-2 gap-3

  // 4. Border
  border border-gray-200 rounded-lg

  // 5. Background
  bg-white

  // 6. Typography
  text-lg font-semibold text-gray-900

  // 7. Effects
  shadow-sm opacity-90
"
```

### Style Extraction Principle

When the same set of styles repeats ≥3 times, extract them:

```tsx
// Repeated
<Text className="text-sm text-gray-500 font-medium">Label 1</Text>
<Text className="text-sm text-gray-500 font-medium">Label 2</Text>
<Text className="text-sm text-gray-500 font-medium">Label 3</Text>

// Option 1: variable
const labelClass = "text-sm text-gray-500 font-medium";
<Text className={labelClass}>Label 1</Text>
<Text className={labelClass}>Label 2</Text>

// Option 2: wrapper component
const Label: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <Text className="text-sm text-gray-500 font-medium">{children}</Text>
);
```

## FAQ

### Q1: Should conditional class names use Tailwind or style?

**A: Prefer style.**

```tsx
// Recommended: use style
<Box
  className="p-4 rounded-lg"
  style={{ backgroundColor: isSelected ? colors.primary : colors.gray }}
/>

// Acceptable: simple binary toggle
<Text className={isError ? "text-red-500" : "text-gray-900"}>

// Avoid: complex conditional class combinations
<Box className={`p-4 ${isSelected ? 'bg-primary-500 border-primary-600' : 'bg-gray-100 border-gray-200'} ${isDisabled ? 'opacity-50' : ''}`}>
```

### Q2: How to handle animation styles?

**A: Animation values must use style.**

```tsx
// Reanimated animation
const animatedStyle = useAnimatedStyle(() => ({
  transform: [{ translateX: offset.value }],
  opacity: opacity.value,
}));

<Animated.View
  className="absolute w-full" // Static layout via className
  style={animatedStyle} // Animation values via style
/>;
```

### Q3: How to handle responsive styles?

**A: Use Tailwind responsive prefixes.**

```tsx
// Responsive via Tailwind
<Box className="p-2 md:p-4 lg:p-6">
<Text className="text-sm md:text-base lg:text-lg">

// When you need exact values from screen size
const { width } = useWindowDimensions();
const columns = width > 768 ? 4 : 2;

<FlatList
  numColumns={columns}
  className="flex-1"
/>
```
