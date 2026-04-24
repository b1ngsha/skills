# Figma Style to RN Style

## Layout Conversion

### Auto Layout → Flex

| Figma Auto Layout       | React Native                            |
| ----------------------- | --------------------------------------- |
| Direction: Vertical     | `flexDirection: 'column'` or `<VStack>` |
| Direction: Horizontal   | `flexDirection: 'row'` or `<HStack>`    |
| Gap: 16                 | `gap: 16` or `space="md"`               |
| Padding: 16             | `p="$4"`                                |
| Alignment: Center       | `alignItems: 'center'`                  |
| Justify: Space Between  | `justifyContent: 'space-between'`       |

### Sizing Constraints

| Figma Constraint  | React Native                   |
| ----------------- | ------------------------------ |
| Fixed Width: 200  | `width={200}`                  |
| Fill Container    | `flex={1}` or `width="100%"`   |
| Hug Contents      | Omit width (default behavior)  |
| Min Width: 100    | `minWidth={100}`               |
| Max Width: 300    | `maxWidth={300}`               |

### Positioning

| Figma Positioning | React Native          |
| ----------------- | --------------------- |
| Absolute Position | `position="absolute"` |
| Top: 10           | `top={10}`            |
| Right: 10         | `right={10}`          |
| Bottom: 10        | `bottom={10}`         |
| Left: 10          | `left={10}`           |

## Style Property Conversion

### Background Color

```tsx
// Figma: Fill: #FFFFFF
// v3: use Tailwind className
<Box className="bg-white" />

// Or use style (dynamic)
<Box style={{ backgroundColor: '#FFFFFF' }} />

// Figma: Fill: rgba(0,0,0,0.5)
<Box className="bg-black/50" />

// Figma: Gradient
// Use expo-linear-gradient
import { LinearGradient } from 'expo-linear-gradient';
<LinearGradient
  colors={['#FF6B6B', '#4ECDC4']}
  start={{ x: 0, y: 0 }}
  end={{ x: 1, y: 0 }}
  style={{ flex: 1 }}
>
  {children}
</LinearGradient>
```

### Border

```tsx
// Figma: Stroke: 1px #E0E0E0
// v3: use Tailwind className
<Box className="border border-outline-200" />

// Or use style
<Box style={{ borderWidth: 1, borderColor: '#E0E0E0' }} />

// Figma: Stroke inside, width 2
<Box className="border-2 border-gray-300" />

// Figma: single-side border
<Box className="border-b border-outline-200" />

// Figma: dashed border
<Box className="border border-dashed border-outline-300" />
```

### Border Radius

```tsx
// Figma: Corner Radius: 8
// v3: use Tailwind className
<Box className="rounded-lg" />  // rounded-lg = 8

// Or use style
<Box style={{ borderRadius: 8 }} />

// Figma: per-corner radius
<Box className="rounded-tl-lg rounded-tr-lg rounded-bl-none rounded-br-none" />

// Circle
<Box className="rounded-full" />  // 9999
```

### Shadow

```tsx
// Figma: Drop Shadow, Y: 2, Blur: 4, Opacity: 0.1
// iOS
<Box
  shadowColor="#000"
  shadowOffset={{ width: 0, height: 2 }}
  shadowOpacity={0.1}
  shadowRadius={4}
/>

// Android (elevation)
<Box elevation={3} />

// Cross-platform
import { Platform } from 'react-native';

const shadowStyle = Platform.select({
  ios: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  android: {
    elevation: 3,
  },
});
```

### Opacity

```tsx
// Figma: Opacity: 50%
<Box className="opacity-50" />
// or
<Box style={{ opacity: 0.5 }} />
```

## Typography Conversion

### Font Properties

```tsx
// Figma: Font Size: 16, Weight: Medium, Line Height: 24
// v3: use Tailwind className
<Text className="text-base font-medium leading-6">
  Text
</Text>

// Or use style
<Text
  style={{
    fontSize: 16,
    fontWeight: '500',
    lineHeight: 24,
  }}
>
  Text
</Text>

// Use Gluestack size prop
<Text size="md" className="font-medium">Text</Text>
```

### Text Alignment

| Figma   | React Native          |
| ------- | --------------------- |
| Left    | `textAlign="left"`    |
| Center  | `textAlign="center"`  |
| Right   | `textAlign="right"`   |
| Justify | `textAlign="justify"` |

### Text Truncation

```tsx
// Figma: Truncate text
<Text numberOfLines={1} ellipsizeMode="tail">
  Very long text...
</Text>

// Multi-line truncation
<Text numberOfLines={2}>
  Very long multi-line text...
</Text>
```

### Letter / Line Spacing

```tsx
// Figma: Letter Spacing: 0.5
<Text letterSpacing={0.5}>Text</Text>

// Figma: Line Height: 150%
<Text lineHeight={24}>Text</Text>  // computed from font size
```

## Image Handling

### Resize Mode

| Figma Fill Mode | RN resizeMode               |
| --------------- | --------------------------- |
| Fill            | `"cover"`                   |
| Fit             | `"contain"`                 |
| Crop            | `"cover"` + overflow hidden |
| Tile            | Not supported               |

```tsx
<Image
  source={{ uri: url }}
  resizeMode="cover"
  style={{ width: 100, height: 100 }}
/>
```

### Image Border Radius

```tsx
<Image source={{ uri: url }} borderRadius={8} overflow="hidden" />
```

## Special Effects

### Blur

```tsx
// Use expo-blur
import { BlurView } from "expo-blur";

<BlurView intensity={50} style={StyleSheet.absoluteFill}>
  {children}
</BlurView>;
```

### Overlay

```tsx
// Semi-transparent overlay
<Box className="absolute inset-0 bg-black/50" />
```

### Unsupported Effects

The following Figma effects need workarounds in RN:

| Figma Effect    | RN Alternative              |
| --------------- | --------------------------- |
| Inner Shadow    | Simulate with border        |
| Layer Blur      | expo-blur (limited cases)   |
| Background Blur | expo-blur                   |
| Blend Mode      | Not supported               |
| Multiple Fills  | Nested View                 |
