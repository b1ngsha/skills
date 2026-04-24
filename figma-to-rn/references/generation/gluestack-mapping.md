# Gluestack-UI v3 Component Usage

> **v3 core change**: Adopts a "Copy-Paste" model — component source is copied into the project's `@/components/ui` directory and imported via relative paths.

## Import Convention

All Gluestack components should be imported from the project's UI directory:

```tsx
// Correct - v3 style
import { Box, Text, Button, ButtonText } from "@/components/ui";

// Wrong - v2 legacy style
import { Box } from "@gluestack-ui/themed";
```

## Common Component APIs

### Box

Generic container:

```tsx
// v3: use Tailwind className
<Box className="bg-background-0 p-4 rounded-lg border border-outline-200">
  {children}
</Box>

// Dynamic styles via style
<Box
  className="p-4 rounded-lg"
  style={{ backgroundColor: isActive ? '#10B981' : '#F3F4F6' }}
>
  {children}
</Box>
```

### VStack / HStack

Layout containers:

```tsx
// Vertical, gap 16px
<VStack space="md" className="p-4">
  <Text>Item 1</Text>
  <Text>Item 2</Text>
</VStack>

// Horizontal, centered
<HStack space="sm" className="items-center justify-between">
  <Text>Left</Text>
  <Text>Right</Text>
</HStack>
```

### Text

Text component:

```tsx
// Use Tailwind className
<Text className="text-md text-typography-900 font-medium">
  Body text
</Text>

<Text className="text-sm text-typography-500">
  Secondary text
</Text>

// Or use component props
<Text size="md" className="text-typography-900 font-medium">
  Body text
</Text>
```

### Button

Button component:

```tsx
// Primary button
<Button action="primary" size="lg" onPress={handlePress}>
  <ButtonText>Confirm</ButtonText>
</Button>

// Button with icon
<Button variant="outline" size="md">
  <ButtonIcon as={PlusIcon} className="mr-1" />
  <ButtonText>Add</ButtonText>
</Button>

// Icon-only button
<Button variant="link" size="sm">
  <ButtonIcon as={SettingsIcon} />
</Button>

// Disabled state
<Button isDisabled>
  <ButtonText>Disabled</ButtonText>
</Button>

// Loading state
<Button isDisabled>
  <ButtonSpinner className="mr-1" />
  <ButtonText>Loading...</ButtonText>
</Button>
```

### Input

Input field:

```tsx
// Basic input
<Input size="md" variant="outline">
  <InputField
    placeholder="Type here..."
    value={value}
    onChangeText={setValue}
  />
</Input>

// Input with icon
<Input size="md">
  <InputSlot className="pl-3">
    <InputIcon as={SearchIcon} className="text-typography-400" />
  </InputSlot>
  <InputField placeholder="Search..." />
  <InputSlot className="pr-3">
    <Pressable onPress={handleClear}>
      <InputIcon as={XIcon} className="text-typography-400" />
    </Pressable>
  </InputSlot>
</Input>

// Password input
<Input size="md">
  <InputField
    type={showPassword ? 'text' : 'password'}
    placeholder="Enter password"
  />
  <InputSlot className="pr-3">
    <Pressable onPress={() => setShowPassword(!showPassword)}>
      <InputIcon as={showPassword ? EyeIcon : EyeOffIcon} />
    </Pressable>
  </InputSlot>
</Input>
```

### Image

Image component:

```tsx
<Image
  source={{ uri: imageUrl }}
  alt="image description"
  size="lg"           // xs, sm, md, lg, xl, 2xl, full
  className="rounded-md"
  resizeMode="cover"
/>

// Fixed size
<Image
  source={{ uri: imageUrl }}
  alt="image description"
  className="w-[100px] h-[100px] rounded-full"
/>
```

### Avatar

Avatar component:

```tsx
<Avatar size="lg">
  <AvatarFallbackText>John Doe</AvatarFallbackText>
  <AvatarImage source={{ uri: avatarUrl }} />
  <AvatarBadge />  {/* online status badge */}
</Avatar>

// Avatar group
<AvatarGroup>
  <Avatar size="md">
    <AvatarImage source={{ uri: url1 }} />
  </Avatar>
  <Avatar size="md">
    <AvatarImage source={{ uri: url2 }} />
  </Avatar>
</AvatarGroup>
```

### Icon

Icon component (paired with lucide-react-native):

```tsx
import { Icon } from '@/components/ui';
import { Heart, Share, MessageCircle } from 'lucide-react-native';

<Icon as={Heart} size="md" className="text-red-500" />
<Icon as={Share} size="sm" className="text-typography-500" />
```

### Pressable

Pressable container:

```tsx
<Pressable
  onPress={handlePress}
  className="active:opacity-70 hover:bg-background-100"
>
  <Box className="p-3">
    <Text>Pressable area</Text>
  </Box>
</Pressable>
```

### Divider

Divider:

```tsx
<Divider className="my-4 bg-outline-200" />

// Vertical divider
<Divider orientation="vertical" className="h-6 mx-2" />
```

### Badge

Badge:

```tsx
<Badge action="success" variant="solid">
  <BadgeText>Done</BadgeText>
</Badge>

<Badge action="error" variant="outline">
  <BadgeIcon as={AlertCircle} className="mr-1" />
  <BadgeText>Error</BadgeText>
</Badge>
```

## v3 Style System

Gluestack v3 integrates deeply with Tailwind CSS:

### Spacing

```tsx
// Use Tailwind className
className = "p-4"; // padding: 16
className = "m-2"; // margin: 8
className = "gap-3"; // gap: 12
className = "px-4 py-2"; // paddingHorizontal, paddingVertical
```

### Colors

```tsx
// Use the project's Tailwind theme colors
className = "bg-primary-500";
className = "text-typography-900";
className = "border-outline-200";
className = "bg-background-0";

// Dark mode
className = "bg-white dark:bg-gray-900";
```

### Sizes

Component-specific size props:

```tsx
<Button size="sm" | "md" | "lg" | "xl" />
<Input size="sm" | "md" | "lg" />
<Avatar size="xs" | "sm" | "md" | "lg" | "xl" | "2xl" />
```

### Radius

```tsx
className = "rounded-sm"; // 2
className = "rounded-md"; // 6
className = "rounded-lg"; // 8
className = "rounded-xl"; // 12
className = "rounded-full"; // 9999
```

## Responsive Design

Use Tailwind breakpoints:

```tsx
<Box className="w-full md:w-1/2 lg:w-1/3">{children}</Box>;

// In RN you may need useWindowDimensions in addition
const { width } = useWindowDimensions();
const isTablet = width >= 768;

<Box className={isTablet ? "w-1/2" : "w-full"}>{children}</Box>;
```

## Dynamic Styles

Static via className, dynamic via style:

```tsx
// Correct
<Box
  className="p-4 rounded-lg"
  style={{ backgroundColor: isActive ? '#10B981' : '#F3F4F6' }}
>
  <Text
    className="font-medium"
    style={{ color: isSelected ? '#FFFFFF' : '#374151' }}
  >
    {label}
  </Text>
</Box>

// Wrong: dynamic styles encoded as conditional classes
<Box className={`p-4 ${isActive ? 'bg-green-500' : 'bg-gray-200'}`}>
```
