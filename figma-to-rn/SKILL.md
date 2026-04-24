---
name: figma-to-rn
description: Convert Figma designs into React Native + Expo + Gluestack-UI code. Covers screenshot analysis, per-node fetching, and page assembly. Trigger on "figma", "design mockup", "design spec", "UI to code", "design to code", "page development", "design slicing", "screen implementation", or any request to turn a Figma frame into RN components.
---

# Figma to React Native Code

> Convert Figma designs into React Native + Expo + Gluestack-UI code.

## Description

Use this skill when the user needs to translate a Figma design into frontend code. Trigger words include: "figma", "design mockup", "design spec", "UI to code", "design to code", "page development", "design slicing".

## Core Strategy: Screenshot First + Per-Node Fetch

⚠️ **Important**: Fetching an entire Figma page in one shot blows the token budget and gets truncated. Always follow this flow:

### Phase 1: Screenshot Analysis

1. User provides a full screenshot of the page.
2. Analyze the visual hierarchy and identify splittable component nodes.
3. Output the hierarchy tree and confirm with the user.

### Phase 2: Per-Node Fetch

1. User supplies a Figma URL per node (with the `node-id` parameter).
2. Generate component code one node at a time.
3. Finish a node before moving to the next.

### Phase 3: Page Assembly

1. Generate the page container component.
2. Compose all child components.
3. Extract shared style constants.

## Tech Stack

- **Framework**: React Native + Expo
- **UI Library**: Gluestack-UI v3 (Copy-Paste mode, imported from `@/components/ui`)
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS (static) + Style object (dynamic)

## Core Conventions

### Style Conventions

| Style Type     | Usage                                  | Example                                                         |
| -------------- | -------------------------------------- | --------------------------------------------------------------- |
| **Static**     | Tailwind CSS (`className`)             | `className="p-4 bg-white rounded-lg"`                           |
| **Dynamic**    | Style object (`style`)                 | `style={{ backgroundColor: isActive ? '#10B981' : '#E5E7EB' }}` |
| **Mixed**      | Static via className, dynamic via style | See example below                                              |

⚠️ **No redundant styles**: Do not write defaults that have no effect (e.g. `opacity-100`, `flex-col` on `VStack`).

### Componentization Conventions

| Scenario                              | Action                            |
| ------------------------------------- | --------------------------------- |
| Same UI appears ≥2 times              | Must extract into a component     |
| Reused across pages                   | Separate file `components/shared/` |
| Reused within a single page           | Separate file `components/[feature]/` |
| Used only in current component, < 50 lines | Keep inline in source file   |

## Quick Reference

### Screenshot Analysis Output Format

```
[PageName]
├── Node 1: [ComponentName]
│   └── Contains: [child element description]
├── Node 2: [ComponentName]
│   └── Contains: [child element description]
└── Node N: [ComponentName]
    └── Contains: [child element description]
```

### Node Splitting Priority

| Priority | Split Criterion       | Notes                  |
| -------- | --------------------- | ---------------------- |
| P0       | Independent function area | Header, Footer, TabBar |
| P1       | Reusable component    | Card, ListItem, Button |
| P2       | Complex interaction   | Form, Modal, Carousel  |
| P3       | Content block         | Section, Banner        |

### Gluestack-UI Component Mapping

| Figma Element  | Gluestack Component             |
| -------------- | ------------------------------- |
| Button         | `<Button>`                      |
| Text input     | `<Input>`                       |
| Text           | `<Text>`                        |
| Image          | `<Image>`                       |
| Card container | `<Box>` + `<VStack>`/`<HStack>` |
| List           | `<FlatList>` + custom item      |
| Icon           | `<Icon>`                        |
| Avatar         | `<Avatar>`                      |
| Switch         | `<Switch>`                      |
| Checkbox       | `<Checkbox>`                    |

### Code Generation Pattern

```typescript
import React from 'react';
// v3: import from local project
import { Box, Text, Button, ButtonText } from '@/components/ui';

interface [ComponentName]Props {
  // explicit type definitions
}

export const [ComponentName]: React.FC<[ComponentName]Props> = (props) => {
  return (
    // Gluestack components + Tailwind className
  );
};
```

### Style Examples

```tsx
// Correct: static via className, dynamic via style
<Pressable
  className="px-4 py-2 rounded-lg"
  style={{
    backgroundColor: isSelected ? '#3B82F6' : '#F3F4F6',
    opacity: disabled ? 0.5 : 1
  }}
>
  <Text
    className="font-medium"
    style={{ color: isSelected ? '#FFFFFF' : '#374151' }}
  >
    {label}
  </Text>
</Pressable>

// Wrong: static styles in style object
<Box style={{ flex: 1, padding: 16, backgroundColor: 'white' }}>

// Wrong: dynamic styles encoded via conditional className
<Box className={`p-4 ${isActive ? 'bg-green-500' : 'bg-gray-200'}`}>
```

## Detailed Rules

See the `references/` directory:

- `analysis/` - Screenshot analysis and hierarchy detection
- `figma/` - Figma data handling
- `generation/` - Code generation rules
  - `componentization.md` - **Componentization design rules**
  - `css-standards.md` - **CSS style rules**
  - `gluestack-mapping.md` - Gluestack-UI component mapping
  - `style-conversion.md` - Style conversion rules
  - `page-assembly.md` - Page assembly rules
- `examples/` - Complete examples

## Output File Layout

```
frontend/
├── screens/
│   └── [PageName].tsx          # Page container
├── components/
│   ├── [Component1].tsx        # Component files
│   ├── [Component2].tsx
│   └── ...
├── theme/
│   └── tokens.ts               # Design tokens
└── types/
    └── [page].ts               # Type definitions
```
