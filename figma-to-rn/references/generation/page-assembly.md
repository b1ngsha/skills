# Page Assembly Rules

## Assembly Flow

After all node components are generated, assemble the page in this order:

### 1. Create the Page Container

```tsx
// frontend/screens/[PageName]Screen.tsx
import React from "react";
import { ScrollView } from "react-native";
import { Box, VStack } from "@/components/ui";
import { useSafeAreaInsets } from "react-native-safe-area-context";

// Import all child components
import { Header } from "@/components/Header";
import { ProductGrid } from "@/components/ProductGrid";
import { Footer } from "@/components/Footer";

export const HomeScreen: React.FC = () => {
  const insets = useSafeAreaInsets();

  return (
    <Box flex={1} bg="$backgroundLight0">
      {/* Fixed header */}
      <Header />

      {/* Scrollable content */}
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ paddingBottom: insets.bottom }}
        showsVerticalScrollIndicator={false}
      >
        <VStack space="md" p="$4">
          <ProductGrid />
          {/* more content... */}
        </VStack>
      </ScrollView>

      {/* Fixed footer */}
      <Footer />
    </Box>
  );
};
```

### 2. Page Layout Patterns

#### Pattern A: Scrollable Page

```tsx
<Box flex={1}>
  <Header /> {/* fixed */}
  <ScrollView flex={1}>
    <Content />
  </ScrollView>
  <Footer /> {/* fixed */}
</Box>
```

#### Pattern B: Tab Page

```tsx
<Box flex={1}>
  <TabContent /> {/* swap based on current tab */}
  <BottomTabBar /> {/* fixed bottom */}
</Box>
```

#### Pattern C: List Page

```tsx
<Box flex={1}>
  <Header />
  <FlatList
    data={items}
    renderItem={({ item }) => <ItemCard item={item} />}
    ListHeaderComponent={<FilterBar />}
    ListEmptyComponent={<EmptyState />}
  />
</Box>
```

#### Pattern D: Form Page

```tsx
<KeyboardAvoidingView
  behavior={Platform.OS === "ios" ? "padding" : "height"}
  flex={1}
>
  <ScrollView>
    <FormContent />
  </ScrollView>
  <SubmitButton /> {/* fixed bottom */}
</KeyboardAvoidingView>
```

## Component Organization

### Directory Structure

```
frontend/
├── screens/
│   └── HomeScreen.tsx           # Page container
├── components/
│   ├── home/                    # Page-scoped components
│   │   ├── HeroBanner.tsx
│   │   ├── CategoryGrid.tsx
│   │   └── ProductSection.tsx
│   └── common/                  # Shared components
│       ├── Header.tsx
│       ├── Footer.tsx
│       └── ProductCard.tsx
├── theme/
│   └── tokens.ts               # Design tokens
└── types/
    └── home.ts                 # Page-specific types
```

### Component File Layout

```tsx
// components/ProductCard.tsx
import React from "react";
import { Box, VStack, HStack, Text, Image, Pressable } from "@/components/ui";

// 1. Type definition
interface ProductCardProps {
  id: string;
  title: string;
  price: number;
  imageUrl: string;
  onPress?: () => void;
}

// 2. Implementation
export const ProductCard: React.FC<ProductCardProps> = ({
  id,
  title,
  price,
  imageUrl,
  onPress,
}) => {
  return (
    <Pressable onPress={onPress} $active={{ opacity: 0.8 }}>
      <Box
        bg="$white"
        borderRadius="$lg"
        overflow="hidden"
        borderWidth={1}
        borderColor="$borderLight200"
      >
        <Image
          source={{ uri: imageUrl }}
          alt={title}
          width="100%"
          height={150}
          resizeMode="cover"
        />
        <VStack p="$3" space="xs">
          <Text size="md" numberOfLines={2} fontWeight="$medium">
            {title}
          </Text>
          <Text size="lg" color="$primary500" fontWeight="$bold">
            ${price.toFixed(2)}
          </Text>
        </VStack>
      </Box>
    </Pressable>
  );
};
```

## State Management Integration

### Local State

```tsx
const [loading, setLoading] = useState(false);
const [data, setData] = useState<Product[]>([]);
```

### Data Fetching

```tsx
import { useQuery } from "@tanstack/react-query";

const { data, isLoading, error } = useQuery({
  queryKey: ["products"],
  queryFn: fetchProducts,
});
```

## Navigation Integration

### Page Navigation

```tsx
import { useNavigation } from "@react-navigation/native";
import type { NativeStackNavigationProp } from "@react-navigation/native-stack";

type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

const navigation = useNavigation<NavigationProp>();

// navigate
navigation.navigate("ProductDetail", { id: productId });
```

### Receiving Params

```tsx
import { useRoute, RouteProp } from "@react-navigation/native";

type RouteProps = RouteProp<RootStackParamList, "ProductDetail">;

const route = useRoute<RouteProps>();
const { id } = route.params;
```

## Style Sharing

### Extract Shared Styles

```tsx
// theme/commonStyles.ts
export const cardStyle = {
  bg: "$white",
  borderRadius: "$lg",
  borderWidth: 1,
  borderColor: "$borderLight200",
  overflow: "hidden",
};

export const sectionStyle = {
  p: "$4",
  mb: "$4",
};
```

### Use Shared Styles

```tsx
import { cardStyle } from "@/theme/commonStyles";

<Box {...cardStyle}>{children}</Box>;
```

## Generated File Manifest Template

````markdown
## Generated Files

### Screens

- `frontend/screens/[PageName]Screen.tsx`

### Components

- `frontend/components/[page]/[Component1].tsx`
- `frontend/components/[page]/[Component2].tsx`
- `frontend/components/common/[SharedComponent].tsx`

### Theme

- `frontend/theme/tokens.ts` (if new tokens added)

### Types

- `frontend/types/[page].ts`

### Usage

```tsx
import { [PageName]Screen } from '@/screens/[PageName]Screen';

// Add to navigation config
<Stack.Screen name="[PageName]" component={[PageName]Screen} />
```
````
