# Gluestack-UI v3 Conventions

Priority: **MEDIUM**

> **Gluestack v3 key change**: uses the "Copy-Paste" model. Component source is copied into the project at `@/components/ui` and imported via relative paths, not from an npm package.

## ui-001: Prefer Gluestack Components

### Issue

Reinventing base components wastes time and may miss accessibility features.

### ❌ Bad

```tsx
// reinvented Button
<TouchableOpacity style={styles.button} onPress={handlePress}>
  <Text style={styles.buttonText}>Confirm</Text>
</TouchableOpacity>

// reinvented Input
<View style={styles.inputContainer}>
  <TextInput style={styles.input} />
</View>

// wrong: importing from the npm package (v2 way)
import { Button, ButtonText } from '@gluestack-ui/themed';
```

### ✅ Good

```tsx
// v3 correct: import from project-local components
import { Button, ButtonText, Input, InputField } from '@/components/ui';

<Button onPress={handlePress} size="md" variant="solid">
  <ButtonText>Confirm</ButtonText>
</Button>

<Input size="md" variant="outline">
  <InputField placeholder="Enter text" />
</Input>
```

### Common Component Mappings

| Reinvented           | Gluestack Replacement                       |
| -------------------- | ------------------------------------------- |
| `<View>` container   | `<Box>`, `<VStack>`, `<HStack>`             |
| `<TouchableOpacity>` | `<Button>`, `<Pressable>`                   |
| Custom Modal         | `<Modal>`, `<AlertDialog>`, `<Actionsheet>` |
| Custom Toast         | `<Toast>`                                   |
| Custom Input         | `<Input>`, `<Textarea>`                     |
| Custom Checkbox      | `<Checkbox>`                                |
| Custom Switch        | `<Switch>`                                  |
| Custom Select        | `<Select>`                                  |

---

## ui-002: Use Theme Tokens

### Issue

Hard-coded colors/spacing/fonts cause inconsistency and are hard to maintain.

### ❌ Bad

```tsx
<View style={{ padding: 16, backgroundColor: "#f5f5f5" }}>
  <Text style={{ fontSize: 14, color: "#333", marginBottom: 8 }}>Title</Text>
</View>
```

### ✅ Good

```tsx
// v3: import from project-local + Tailwind CSS
import { Box, Text } from '@/components/ui';

// recommended: Tailwind CSS className
<Box className="p-4 bg-background-100">
  <Text className="text-sm text-typography-900 mb-2">
    Title
  </Text>
</Box>

// or native View + Tailwind
<View className="p-4 bg-gray-100">
  <Text className="text-sm text-gray-900 mb-2">Title</Text>
</View>
```

### v3 Style System

```tsx
// v3 prefers Tailwind CSS className
// spacing
className = "p-4"; // padding: 16
className = "m-2"; // margin: 8
className = "gap-3"; // gap: 12

// colors (project-defined Tailwind theme colors)
className = "bg-primary-500";
className = "text-typography-900";
className = "border-outline-200";

// sizes (component props)
size = "sm" | "md" | "lg" | "xl";

// border radius
className = "rounded-md" | "rounded-lg" | "rounded-full";
```

---

## ui-003: Use VStack/HStack for Layout

### Issue

Deeply nested `View` is hard to read.

### ❌ Bad

```tsx
<View style={{ flexDirection: "column" }}>
  <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
    <Text>Left</Text>
    <Text>Right</Text>
  </View>
  <View style={{ marginTop: 8 }}>
    <Text>Content</Text>
  </View>
</View>
```

### ✅ Good

```tsx
import { VStack, HStack, Box, Text } from "@/components/ui";

<VStack space="md">
  <HStack className="justify-between">
    <Text>Left</Text>
    <Text>Right</Text>
  </HStack>
  <Box>
    <Text>Content</Text>
  </Box>
</VStack>;
```

---

## ui-004: Provide Accessibility Attributes

### Issue

Missing accessibility attributes block screen-reader users.

### ❌ Bad

```tsx
<Pressable onPress={handleClose}>
  <Icon name="close" />
</Pressable>

<Image source={productImage} />
```

### ✅ Good

```tsx
<Pressable
  onPress={handleClose}
  accessibilityRole="button"
  accessibilityLabel="Close"
>
  <Icon name="close" />
</Pressable>

<Image
  source={productImage}
  accessibilityLabel="Product image: red dress"
/>

// Gluestack components usually have built-in accessibility support
<Button accessibilityLabel="Confirm purchase">
  <ButtonText>Confirm</ButtonText>
</Button>
```

---

## ui-005: Use Actionsheet Correctly

### Issue

Hand-rolled bottom sheets miss gesture and animation support.

### ✅ Good

```tsx
import {
  Actionsheet,
  ActionsheetBackdrop,
  ActionsheetContent,
  ActionsheetDragIndicator,
  ActionsheetDragIndicatorWrapper,
  ActionsheetItem,
  ActionsheetItemText,
} from "@/components/ui";

const [isOpen, setIsOpen] = useState(false);

<Actionsheet isOpen={isOpen} onClose={() => setIsOpen(false)}>
  <ActionsheetBackdrop />
  <ActionsheetContent>
    <ActionsheetDragIndicatorWrapper>
      <ActionsheetDragIndicator />
    </ActionsheetDragIndicatorWrapper>

    <ActionsheetItem onPress={handleEdit}>
      <ActionsheetItemText>Edit</ActionsheetItemText>
    </ActionsheetItem>

    <ActionsheetItem onPress={handleDelete}>
      <ActionsheetItemText>Delete</ActionsheetItemText>
    </ActionsheetItem>
  </ActionsheetContent>
</Actionsheet>;
```

---

## ui-006: Use Modal Correctly

### ✅ Good

```tsx
import {
  Modal,
  ModalBackdrop,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  ModalCloseButton,
} from "@/components/ui";

<Modal isOpen={isOpen} onClose={() => setIsOpen(false)}>
  <ModalBackdrop />
  <ModalContent>
    <ModalHeader>
      <Heading size="lg">Title</Heading>
      <ModalCloseButton>
        <Icon as={CloseIcon} />
      </ModalCloseButton>
    </ModalHeader>

    <ModalBody>
      <Text>Body</Text>
    </ModalBody>

    <ModalFooter>
      <Button variant="outline" onPress={() => setIsOpen(false)}>
        <ButtonText>Cancel</ButtonText>
      </Button>
      <Button onPress={handleConfirm}>
        <ButtonText>Confirm</ButtonText>
      </Button>
    </ModalFooter>
  </ModalContent>
</Modal>;
```

---

## ui-007: Form Components

### ✅ Good

```tsx
import {
  FormControl,
  FormControlLabel,
  FormControlLabelText,
  FormControlHelper,
  FormControlHelperText,
  FormControlError,
  FormControlErrorText,
  Input,
  InputField,
} from "@/components/ui";

<FormControl isInvalid={!!errors.email}>
  <FormControlLabel>
    <FormControlLabelText>Email</FormControlLabelText>
  </FormControlLabel>

  <Input>
    <InputField
      value={email}
      onChangeText={setEmail}
      placeholder="Enter email"
      keyboardType="email-address"
      autoCapitalize="none"
    />
  </Input>

  <FormControlHelper>
    <FormControlHelperText>We won't share your email</FormControlHelperText>
  </FormControlHelper>

  <FormControlError>
    <FormControlErrorText>{errors.email}</FormControlErrorText>
  </FormControlError>
</FormControl>;
```

---

## ui-008: Theme Extension via Tailwind Config

### Issue

Overriding per-instance leads to inconsistency.

### ❌ Bad

```tsx
// repeated every time
<Button className="bg-[#6366F1] active:bg-[#4F46E5]">
  <ButtonText>Button</ButtonText>
</Button>
```

### ✅ Good

```tsx
// v3: extend the theme via Tailwind config
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: {
          500: "#6366F1",
          600: "#4F46E5",
        },
      },
    },
  },
};

// usage
<Button className="bg-brand-500 active:bg-brand-600">
  <ButtonText>Button</ButtonText>
</Button>;

// or define a custom Button variant
// in components/ui/button/index.tsx
<Button action="brand">
  <ButtonText>Button</ButtonText>
</Button>;
```

---

## ui-009: v3 Uses Tailwind CSS Uniformly

### Principles

- v3 components are tightly integrated with Tailwind.
- All components prefer `className` for styling.
- Component-specific properties (e.g. `size`, `action`) use props.
- Dynamic styles use the `style` prop.

### ✅ Good

```tsx
import { Button, ButtonText, Box, Text } from "@/components/ui";

// Gluestack v3 component + Tailwind className
<Box className="flex-1 p-4 bg-white">
  <Text className="text-lg font-semibold mb-4">Title</Text>

  {/* component-specific props as props, styles as className */}
  <Button size="md" action="primary" className="mt-4">
    <ButtonText>Confirm</ButtonText>
  </Button>

  {/* dynamic styles via style */}
  <Box
    className="p-4 rounded-lg"
    style={{ backgroundColor: isActive ? "#10B981" : "#F3F4F6" }}
  >
    <Text>Content</Text>
  </Box>
</Box>;
```

---

## ui-010: Button vs Pressable

### Principle

Choose based on the button's visual and semantic characteristics:

| Button Type                       | Recommended             | Reason                            |
| --------------------------------- | ----------------------- | --------------------------------- |
| Has background, clearly a button  | `Button`                | Built-in button semantics & state |
| Pure icon, very small (<36px)     | `Pressable`             | Avoid heavy default style overrides |
| Action button with text           | `Button` + `ButtonText` | Clear semantics, consistent style |
| Icon button (≥36px)               | `Button` + `ButtonIcon` | Built-in accessibility            |

### ❌ Bad

```tsx
// clearly a button but uses Pressable, requires manual accessibilityRole
<Pressable
  onPress={handleSearch}
  className="rounded-full bg-primary-500 px-4 py-2"
  accessibilityRole="button"
  accessibilityLabel="Search"
>
  <SearchIcon />
</Pressable>
```

### ✅ Good

```tsx
// button with background — use Button
<Button
  onPress={handleSearch}
  className="rounded-full bg-primary-500 px-4 py-2 h-auto min-w-0"
  accessibilityLabel="Search"
>
  <ButtonIcon as={SearchIcon} className="w-[18px] h-[18px] text-white" />
</Button>

// pure icon, small touch target — use Pressable
<Pressable
  onPress={onCameraPress}
  className="w-[22px] h-[22px] justify-center items-center"
  accessibilityRole="button"
  accessibilityLabel="Camera"
  hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
>
  <CameraIcon width={22} height={22} />
</Pressable>
```

### Button Style Override Tips

When customizing `Button`, you often need to override defaults:

```tsx
// override default min width and height
className="min-w-0 h-auto"

// override default padding
className="p-0"

// circular button
className="w-9 h-9 min-w-0 p-0 rounded-full"
```
