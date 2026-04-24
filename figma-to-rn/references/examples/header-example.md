# Complete Example: Header Component

## Figma Design Description

```
Header component
├── Logo (left image)
├── SearchBar (center search input)
│   ├── SearchIcon
│   └── Placeholder Text
└── Actions (right action area)
    ├── NotificationIcon
    └── Avatar
```

## Generated Code

### types/header.ts

```typescript
export interface HeaderProps {
  onSearch?: (keyword: string) => void;
  onNotificationPress?: () => void;
  onAvatarPress?: () => void;
  notificationCount?: number;
  avatarUrl?: string;
  userName?: string;
}
```

### components/Header.tsx

```tsx
import React, { useState } from "react";
import {
  Box,
  HStack,
  Input,
  InputField,
  InputSlot,
  InputIcon,
  Avatar,
  AvatarImage,
  AvatarFallbackText,
  Pressable,
  Text,
  Image,
} from "@/components/ui";
import { Search, Bell } from "lucide-react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import type { HeaderProps } from "@/types/header";

export const Header: React.FC<HeaderProps> = ({
  onSearch,
  onNotificationPress,
  onAvatarPress,
  notificationCount = 0,
  avatarUrl,
  userName = "User",
}) => {
  const insets = useSafeAreaInsets();
  const [searchValue, setSearchValue] = useState("");

  const handleSearchSubmit = () => {
    onSearch?.(searchValue);
  };

  return (
    <Box
      className="bg-white border-b border-outline-200 px-4 pb-3"
      style={{ paddingTop: insets.top }}
    >
      <HStack className="items-center" space="md">
        {/* Logo */}
        <Image
          source={require("@/assets/logo.png")}
          alt="Logo"
          className="w-8 h-8"
        />

        {/* Search input */}
        <Box className="flex-1">
          <Input size="sm" variant="outline" className="rounded-full">
            <InputSlot className="pl-3">
              <InputIcon
                as={Search}
                className="text-typography-400"
                size="sm"
              />
            </InputSlot>
            <InputField
              placeholder="Search products..."
              value={searchValue}
              onChangeText={setSearchValue}
              onSubmitEditing={handleSearchSubmit}
              returnKeyType="search"
            />
          </Input>
        </Box>

        {/* Right actions */}
        <HStack className="items-center" space="sm">
          {/* Notification button */}
          <Pressable
            onPress={onNotificationPress}
            className="relative p-2 active:opacity-70"
          >
            <Bell size={24} color="#333" />
            {notificationCount > 0 && (
              <Box className="absolute top-0 right-0 bg-error-500 rounded-full min-w-[16px] h-4 items-center justify-center">
                <Text className="text-2xs text-white font-bold">
                  {notificationCount > 99 ? "99+" : notificationCount}
                </Text>
              </Box>
            )}
          </Pressable>

          {/* Avatar */}
          <Pressable onPress={onAvatarPress} className="active:opacity-70">
            <Avatar size="sm">
              <AvatarFallbackText>{userName}</AvatarFallbackText>
              {avatarUrl && <AvatarImage source={{ uri: avatarUrl }} />}
            </Avatar>
          </Pressable>
        </HStack>
      </HStack>
    </Box>
  );
};
```

## Usage Example

```tsx
import { Header } from "@/components/Header";

const HomeScreen = () => {
  const handleSearch = (keyword: string) => {
    console.log("Search:", keyword);
  };

  return (
    <Box flex={1}>
      <Header
        onSearch={handleSearch}
        onNotificationPress={() => navigation.navigate("Notifications")}
        onAvatarPress={() => navigation.navigate("Profile")}
        notificationCount={5}
        avatarUrl="https://example.com/avatar.jpg"
        userName="John Doe"
      />
      {/* other content */}
    </Box>
  );
};
```

## Key Notes

1. **v3 imports**: import components from `@/components/ui`.
2. **Tailwind styles**: use `className` for static styles.
3. **Dynamic styles**: use `style` for runtime values like safe-area insets.
4. **Safe area**: use `useSafeAreaInsets` to handle notches.
5. **Badge**: red dot on the notification icon uses Tailwind absolute positioning.
6. **Avatar**: use the `Avatar` component with fallback text support.
7. **Press feedback**: use `active:opacity-70` for press feedback.
