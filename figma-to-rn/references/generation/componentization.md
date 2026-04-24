# Componentization Design Rules

## Core Principle

The goal of componentization is to **boost reuse, lower maintenance cost, and improve readability**.

## When to Componentize

### 1. Must Componentize

| Scenario             | Criteria                          | Example                              |
| -------------------- | --------------------------------- | ------------------------------------ |
| **Repeating UI**     | Same/similar UI appears ≥2 times  | ProductCard, ListItem, Tag           |
| **Independent area** | Owns its own logic or state       | SearchBar, FilterPanel, Pagination   |
| **Cross-page reuse** | Used by multiple pages            | Header, Footer, TabBar, Modal        |
| **Complex interaction** | Multiple event handlers         | Form, Carousel, DatePicker           |

### 2. Optional Componentization

| Scenario             | Criteria                            | Recommendation               |
| -------------------- | ----------------------------------- | ---------------------------- |
| **Clear semantics**  | Logically a standalone unit         | Componentize for readability |
| **Large code block** | Single block > 50 lines of JSX      | Componentize for maintenance |
| **Possible reuse**   | Used once now but likely later      | Componentize for extensibility |

### 3. Do Not Componentize

| Scenario                        | Reason                                  |
| ------------------------------- | --------------------------------------- |
| 3-5 line trivial layouts        | Adds unnecessary file/jump cost         |
| Used once with no reuse outlook | Over-abstraction                        |
| Tightly coupled to parent state | Splitting requires heavy prop drilling  |

## Splitting Strategy

### Separate File vs Inline in Source

```
┌─────────────────────────────────────────────────────────────┐
│              Should the component live in its own file?     │
└─────────────────────────────────────────────────────────────┘
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
    ┌──────────────┐            ┌──────────────┐
    │ Separate file │           │ Keep inline   │
    │ components/  │            │ Same source   │
    └──────────────┘            └──────────────┘
         Use when:                    Use when:
    • Reused across files          • Used only here
    • > 80 lines of code           • < 50 lines of code
    • Has its own Props interface  • Tightly coupled to parent state
    • Needs independent tests      • Simple grouping layout
    • Team-agreed shared component • Temporary extraction
```

### Decision Flow

```typescript
// Q1: Reused across files?
if (usedInMultipleFiles) {
  return "Separate file: components/shared/";
}

// Q2: Code too large?
if (jsxLines > 80) {
  return "Separate file: components/[FeatureName]/";
}

// Q3: Has its own Props interface?
if (hasDistinctPropsInterface && jsxLines > 30) {
  return "Separate file";
}

// Q4: Simple grouping layout?
if (jsxLines < 30 && noComplexLogic) {
  return "Keep inline; define inside the component";
}

// Default: keep inline
return "Keep inline";
```

## Component Design Rules

### 1. Props Interface Design

```typescript
// Good: clear interface, required vs optional well separated
interface ProductCardProps {
  // Required props
  product: Product;
  onPress: (id: string) => void;

  // Optional props (with defaults)
  showPrice?: boolean;
  variant?: "compact" | "full";
  testID?: string;
}

// Bad: too many props, fuzzy interface
interface ProductCardProps {
  id: string;
  title: string;
  price: number;
  image: string;
  description: string;
  category: string;
  rating: number;
  // ... too many discrete fields
}
```

**Rules:**

- Cap Props at **3-7**.
- Group related fields into objects (use `product` instead of spreading `title`, `price`, `image`).
- Callbacks start with `on` (`onPress`, `onChange`).
- Optional props use `?` and provide sensible defaults.

### 2. Component Hierarchy

```
components/
├── ui/                    # Base UI components (Button, Input, Card)
│   └── Button.tsx
├── shared/                # Cross-domain shared components
│   ├── Header.tsx
│   └── TabBar.tsx
├── [FeatureName]/         # Feature components
│   ├── ProductCard.tsx
│   └── ProductList.tsx
└── index.ts               # Export entry
```

### 3. Component File Layout

```typescript
// components/ProductCard.tsx

import React, { memo } from "react";
import { Box, Text, Image, Pressable } from "@/components/ui";
import type { Product } from "@/types";

// 1. Interface definition
interface ProductCardProps {
  product: Product;
  onPress: (id: string) => void;
  variant?: "compact" | "full";
}

// 2. Sub-component (only used here, kept inline)
const PriceTag: React.FC<{ price: number }> = ({ price }) => (
  <Text className="text-primary-600 font-semibold">${price.toFixed(2)}</Text>
);

// 3. Main component
export const ProductCard: React.FC<ProductCardProps> = memo(
  ({ product, onPress, variant = "full" }) => {
    const handlePress = () => onPress(product.id);

    return (
      <Pressable onPress={handlePress} className="bg-white rounded-lg p-4">
        <Image
          source={{ uri: product.image }}
          className="w-full h-40 rounded-md"
        />
        <Text className="text-lg font-medium mt-2">{product.title}</Text>
        {variant === "full" && <PriceTag price={product.price} />}
      </Pressable>
    );
  }
);

ProductCard.displayName = "ProductCard";
```

## Reuse Levels

```
┌─────────────────────────────────────────────────────────────┐
│                       Reuse Pyramid                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│     Level 4: Cross-project reuse                             │
│              ↑ NPM package / component library              │
│     ─────────────────────                                   │
│     Level 3: Cross-domain reuse                              │
│              ↑ components/shared/                           │
│     ─────────────────────                                   │
│     Level 2: Within-domain reuse                             │
│              ↑ components/[Feature]/                        │
│     ─────────────────────                                   │
│     Level 1: Within-page reuse                               │
│              ↑ Inline definition                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Componentization Opportunity Checklist

When analyzing screenshots/code, look for these patterns:

### Visual Repetition

- [ ] Similar cards or list items?
- [ ] Repeating Header/Footer?
- [ ] Repeating buttons/tags/badges?

### Structural Repetition

- [ ] Repeating layout patterns (image-left text-right, image-top text-bottom)?
- [ ] Repeating form field combinations?
- [ ] Repeating status displays (empty, loading, error)?

### Behavioral Repetition

- [ ] Repeating tap/swipe interactions?
- [ ] Repeating animations/transitions?
- [ ] Repeating data-loading patterns?

## Output Example

When analyzing screenshots, emit componentization recommendations:

```markdown
## Componentization Analysis

### Reusable Components (separate file)

| Component   | Reuses | File Location                       | Notes                                       |
| ----------- | ------ | ----------------------------------- | ------------------------------------------- |
| ProductCard | 6      | components/product/ProductCard.tsx  | Product card; used by list/recommend/favorites |
| Tag         | 3      | components/ui/Tag.tsx               | Tag; used by product/category/search        |

### Standalone Components (page-specific)

| Component   | Location                          | Notes                       |
| ----------- | --------------------------------- | --------------------------- |
| HeroBanner  | components/home/HeroBanner.tsx    | Home-only carousel          |
| CategoryNav | components/home/CategoryNav.tsx   | Home category navigation    |

### Inline Components (kept in source file)

| Component         | Owning File      | Notes                            |
| ----------------- | ---------------- | -------------------------------- |
| SectionHeader     | HomePage.tsx     | Only 10 lines; home only         |
| EmptyPlaceholder  | ProductList.tsx  | Only 5 lines; tightly coupled to list |
```
