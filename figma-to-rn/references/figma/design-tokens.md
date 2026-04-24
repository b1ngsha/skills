# Design Token Extraction Rules

## Token Categories

### 1. Color Tokens

Extract colors from Figma and convert into tokens:

```typescript
// frontend/theme/colors.ts
export const colors = {
  // Brand colors
  primary: {
    50: "#E3F2FD",
    100: "#BBDEFB",
    500: "#2196F3", // primary
    600: "#1E88E5",
    700: "#1976D2",
  },

  // Semantic colors
  semantic: {
    success: "#4CAF50",
    warning: "#FF9800",
    error: "#F44336",
    info: "#2196F3",
  },

  // Neutral colors
  neutral: {
    white: "#FFFFFF",
    gray50: "#FAFAFA",
    gray100: "#F5F5F5",
    gray200: "#EEEEEE",
    gray500: "#9E9E9E",
    gray900: "#212121",
    black: "#000000",
  },

  // Text colors
  text: {
    primary: "#212121",
    secondary: "#757575",
    disabled: "#BDBDBD",
    inverse: "#FFFFFF",
  },

  // Background colors
  background: {
    default: "#FFFFFF",
    paper: "#FAFAFA",
    elevated: "#FFFFFF",
  },
};
```

### 2. Typography Tokens

```typescript
// frontend/theme/typography.ts
export const typography = {
  // Font families
  fontFamily: {
    regular: "PingFang SC",
    medium: "PingFang SC",
    semibold: "PingFang SC",
    bold: "PingFang SC",
  },

  // Font sizes
  fontSize: {
    xs: 10,
    sm: 12,
    md: 14,
    lg: 16,
    xl: 18,
    "2xl": 20,
    "3xl": 24,
    "4xl": 28,
    "5xl": 32,
  },

  // Line heights
  lineHeight: {
    tight: 1.25,
    normal: 1.5,
    relaxed: 1.75,
  },

  // Font weights
  fontWeight: {
    regular: "400",
    medium: "500",
    semibold: "600",
    bold: "700",
  },
};

// Preset text styles
export const textStyles = {
  h1: {
    fontSize: typography.fontSize["4xl"],
    fontWeight: typography.fontWeight.bold,
    lineHeight: typography.lineHeight.tight,
  },
  h2: {
    fontSize: typography.fontSize["3xl"],
    fontWeight: typography.fontWeight.semibold,
    lineHeight: typography.lineHeight.tight,
  },
  body1: {
    fontSize: typography.fontSize.lg,
    fontWeight: typography.fontWeight.regular,
    lineHeight: typography.lineHeight.normal,
  },
  body2: {
    fontSize: typography.fontSize.md,
    fontWeight: typography.fontWeight.regular,
    lineHeight: typography.lineHeight.normal,
  },
  caption: {
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.regular,
    lineHeight: typography.lineHeight.normal,
  },
};
```

### 3. Spacing Tokens

```typescript
// frontend/theme/spacing.ts
export const spacing = {
  // Base scale (multiples of 4)
  0: 0,
  0.5: 2,
  1: 4,
  2: 8,
  3: 12,
  4: 16,
  5: 20,
  6: 24,
  8: 32,
  10: 40,
  12: 48,
  16: 64,
  20: 80,

  // Semantic spacing
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  "2xl": 48,
};
```

### 4. Radius Tokens

```typescript
// frontend/theme/radius.ts
export const radius = {
  none: 0,
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  "2xl": 24,
  full: 9999,
};
```

### 5. Shadow Tokens

```typescript
// frontend/theme/shadows.ts
import { Platform } from "react-native";

export const shadows = {
  none: {},
  sm: Platform.select({
    ios: {
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 1 },
      shadowOpacity: 0.05,
      shadowRadius: 2,
    },
    android: {
      elevation: 1,
    },
  }),
  md: Platform.select({
    ios: {
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.1,
      shadowRadius: 4,
    },
    android: {
      elevation: 3,
    },
  }),
  lg: Platform.select({
    ios: {
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.15,
      shadowRadius: 8,
    },
    android: {
      elevation: 6,
    },
  }),
};
```

## Figma Value Conversion

### Colors

| Figma Format             | RN Format                   |
| ------------------------ | --------------------------- |
| `#FF5722`                | `'#FF5722'`                 |
| `rgba(255, 87, 34, 0.5)` | `'rgba(255, 87, 34, 0.5)'`  |
| Gradient                 | Use `expo-linear-gradient`  |

### Sizes

| Figma Unit | RN Handling                         |
| ---------- | ----------------------------------- |
| px         | Use the numeric value directly      |
| %          | Use the `'50%'` string              |
| Auto       | Use `flex: 1` or omit               |

### Font Weights

| Figma Weight | RN fontWeight |
| ------------ | ------------- |
| Thin         | '100'         |
| Light        | '300'         |
| Regular      | '400'         |
| Medium       | '500'         |
| Semi Bold    | '600'         |
| Bold         | '700'         |
| Extra Bold   | '800'         |
