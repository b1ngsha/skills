# Figma Element to RN Component Mapping

> **Gluestack v3**: Components are imported from `@/components/ui` and styled with Tailwind className.

## Base Component Mapping

### Containers

| Figma Element   | Gluestack Component     | Notes              |
| --------------- | ----------------------- | ------------------ |
| Frame (vertical)   | `<VStack>`              | Vertical layout    |
| Frame (horizontal) | `<HStack>`              | Horizontal layout  |
| Frame (generic)    | `<Box>`                 | Generic container  |
| Auto Layout        | `<VStack>` / `<HStack>` | Pick by direction  |
| Group              | `<Box>`                 | Group container    |

### Text

| Figma Element | Gluestack Component       | Props                   |
| ------------- | ------------------------- | ----------------------- |
| Text          | `<Text>`                  | `size`, `bold`, `color` |
| Heading       | `<Heading>`               | `size`                  |
| Link Text     | `<Link><LinkText></Link>` | `href`                  |

### Buttons

| Figma Element    | Gluestack Component | Variant               |
| ---------------- | ------------------- | --------------------- |
| Primary Button   | `<Button>`          | `action="primary"`    |
| Secondary Button | `<Button>`          | `variant="outline"`   |
| Text Button      | `<Button>`          | `variant="link"`      |
| Icon Button      | `<Button>`          | Only `<ButtonIcon>`   |
| Disabled Button  | `<Button>`          | `isDisabled`          |

```tsx
// v3 button examples
import { Button, ButtonText, ButtonIcon } from '@/components/ui';

<Button action="primary" size="lg">
  <ButtonText>Confirm</ButtonText>
</Button>

<Button variant="outline" size="md">
  <ButtonIcon as={PlusIcon} />
  <ButtonText>Add</ButtonText>
</Button>
```

### Inputs

| Figma Element  | Gluestack Component                      | Notes             |
| -------------- | ---------------------------------------- | ----------------- |
| Text Input     | `<Input><InputField /></Input>`          | Single line       |
| Text Area      | `<Textarea><TextareaInput /></Textarea>` | Multi line        |
| Search Input   | `<Input>` + `<InputSlot>`                | With icon         |
| Password Input | `<Input>`                                | `type="password"` |

```tsx
// v3 input example
import { Input, InputField, InputSlot, InputIcon } from "@/components/ui";

<Input size="md" variant="outline">
  <InputSlot className="pl-3">
    <InputIcon as={SearchIcon} />
  </InputSlot>
  <InputField placeholder="Search..." />
</Input>;
```

### Selection

| Figma Element   | Gluestack Component |
| --------------- | ------------------- |
| Checkbox        | `<Checkbox>`        |
| Radio           | `<Radio>`           |
| Switch          | `<Switch>`          |
| Select/Dropdown | `<Select>`          |

### Media

| Figma Element | Gluestack Component | Notes                    |
| ------------- | ------------------- | ------------------------ |
| Image         | `<Image>`           | Use `source` prop        |
| Avatar        | `<Avatar>`          | User avatar              |
| Icon          | `<Icon>`            | Pair with lucide-react-native |

```tsx
// v3 image example
import { Image, Avatar, AvatarImage, AvatarFallbackText } from '@/components/ui';

<Image
  source={{ uri: imageUrl }}
  alt="description"
  size="lg"
  className="rounded-md"
/>

// Avatar example
<Avatar size="lg">
  <AvatarFallbackText>John Doe</AvatarFallbackText>
  <AvatarImage source={{ uri: avatarUrl }} />
</Avatar>
```

### Feedback

| Figma Element | Gluestack Component |
| ------------- | ------------------- |
| Toast         | `<Toast>`           |
| Alert         | `<Alert>`           |
| Modal         | `<Modal>`           |
| ActionSheet   | `<Actionsheet>`     |
| Spinner       | `<Spinner>`         |
| Progress      | `<Progress>`        |

### Navigation

| Figma Element  | Implementation             |
| -------------- | -------------------------- |
| Tab Bar        | `<HStack>` + custom styles |
| Navigation Bar | `<HStack>` + custom styles |
| Breadcrumb     | `<HStack>` + `<Text>`      |

## Layout Pattern Mapping

### Flex Layout

```tsx
import { VStack, HStack, Box } from '@/components/ui';

// Figma: Auto Layout, Direction: Vertical, Gap: 16
<VStack space="md">
  {children}
</VStack>

// Figma: Auto Layout, Direction: Horizontal, Gap: 8
<HStack space="sm">
  {children}
</HStack>

// Figma: Alignment: Center
<Box className="items-center justify-center">
  {children}
</Box>
```

### Absolute Positioning

```tsx
// Figma: absolutely positioned element
<Box className="absolute top-2.5 right-2.5">{children}</Box>
```

### Responsive Width

```tsx
// Figma: Width: Fill
<Box className="flex-1">
  {children}
</Box>

// Figma: Width: Fixed 200
<Box className="w-[200px]">
  {children}
</Box>

// Figma: Width: 50%
<Box className="w-1/2">
  {children}
</Box>
```

## Style Property Mapping

### Border

| Figma Property | RN Property                  |
| -------------- | ---------------------------- |
| Border Width   | `borderWidth`                |
| Border Color   | `borderColor`                |
| Border Radius  | `borderRadius`               |
| Border Style   | `borderStyle` (solid/dashed) |

### Effects

| Figma Effect | RN Implementation                              |
| ------------ | ---------------------------------------------- |
| Drop Shadow  | `shadow` prop or `Platform.select`             |
| Inner Shadow | Not supported; simulate with border            |
| Blur         | `expo-blur` or `@react-native-community/blur` |

### Spacing

| Figma Property | RN Property                             |
| -------------- | --------------------------------------- |
| Padding        | `p`, `px`, `py`, `pt`, `pb`, `pl`, `pr` |
| Margin         | `m`, `mx`, `my`, `mt`, `mb`, `ml`, `mr` |
| Gap            | `space` (VStack/HStack)                 |
