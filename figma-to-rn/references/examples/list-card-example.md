# Complete Example: List Card Component

## Figma Design Description

```
ProductCard component
├── Image (product image)
├── Content
│   ├── Title (product title, max 2 lines)
│   ├── Tags (tag group)
│   │   ├── Tag1 (e.g., Free Shipping)
│   │   └── Tag2 (e.g., Best Seller)
│   ├── PriceRow
│   │   ├── CurrentPrice
│   │   └── OriginalPrice (strikethrough)
│   └── SellerInfo
│       ├── Avatar
│       └── Name
└── LikeButton (top-right favorite button)
```

## Generated Code

### types/product.ts

```typescript
export interface Product {
  id: string;
  title: string;
  imageUrl: string;
  currentPrice: number;
  originalPrice?: number;
  tags?: string[];
  seller: {
    id: string;
    name: string;
    avatarUrl?: string;
  };
  isLiked?: boolean;
}

export interface ProductCardProps {
  product: Product;
  onPress?: () => void;
  onLikePress?: () => void;
}
```

### components/ProductCard.tsx

```tsx
import React from "react";
import {
  Box,
  VStack,
  HStack,
  Text,
  Image,
  Pressable,
  Avatar,
  AvatarImage,
  AvatarFallbackText,
  Badge,
  BadgeText,
} from "@/components/ui";
import { Heart } from "lucide-react-native";
import type { ProductCardProps } from "@/types/product";

export const ProductCard: React.FC<ProductCardProps> = ({
  product,
  onPress,
  onLikePress,
}) => {
  const {
    title,
    imageUrl,
    currentPrice,
    originalPrice,
    tags,
    seller,
    isLiked,
  } = product;

  return (
    <Pressable onPress={onPress} $active={{ opacity: 0.9 }}>
      <Box
        bg="$white"
        borderRadius="$lg"
        overflow="hidden"
        borderWidth={1}
        borderColor="$borderLight200"
      >
        {/* Product image */}
        <Box position="relative">
          <Image
            source={{ uri: imageUrl }}
            alt={title}
            width="100%"
            height={180}
            resizeMode="cover"
          />

          {/* Favorite button */}
          <Pressable
            position="absolute"
            top="$2"
            right="$2"
            bg="rgba(255,255,255,0.9)"
            borderRadius="$full"
            p="$2"
            onPress={(e) => {
              e.stopPropagation();
              onLikePress?.();
            }}
            $active={{ opacity: 0.7 }}
          >
            <Heart
              size={20}
              color={isLiked ? "#F43F5E" : "#9CA3AF"}
              fill={isLiked ? "#F43F5E" : "transparent"}
            />
          </Pressable>
        </Box>

        {/* Content */}
        <VStack p="$3" space="sm">
          {/* Title */}
          <Text
            size="md"
            fontWeight="$medium"
            numberOfLines={2}
            color="$textLight900"
          >
            {title}
          </Text>

          {/* Tags */}
          {tags && tags.length > 0 && (
            <HStack space="xs" flexWrap="wrap">
              {tags.map((tag, index) => (
                <Badge key={index} action="info" variant="outline" size="sm">
                  <BadgeText>{tag}</BadgeText>
                </Badge>
              ))}
            </HStack>
          )}

          {/* Price */}
          <HStack alignItems="baseline" space="sm">
            <HStack alignItems="baseline" space="xs">
              <Text size="sm" color="$error500" fontWeight="$bold">
                $
              </Text>
              <Text size="xl" color="$error500" fontWeight="$bold">
                {currentPrice.toFixed(2)}
              </Text>
            </HStack>
            {originalPrice && originalPrice > currentPrice && (
              <Text
                size="sm"
                color="$textLight400"
                textDecorationLine="line-through"
              >
                ${originalPrice.toFixed(2)}
              </Text>
            )}
          </HStack>

          {/* Seller info */}
          <HStack alignItems="center" space="xs">
            <Avatar size="2xs">
              <AvatarFallbackText>{seller.name}</AvatarFallbackText>
              {seller.avatarUrl && (
                <AvatarImage source={{ uri: seller.avatarUrl }} />
              )}
            </Avatar>
            <Text size="sm" color="$textLight500" numberOfLines={1} flex={1}>
              {seller.name}
            </Text>
          </HStack>
        </VStack>
      </Box>
    </Pressable>
  );
};
```

### components/ProductGrid.tsx

```tsx
import React from "react";
import { FlatList, useWindowDimensions } from "react-native";
import { Box } from "@/components/ui";
import { ProductCard } from "./ProductCard";
import type { Product } from "@/types/product";

interface ProductGridProps {
  products: Product[];
  onProductPress?: (product: Product) => void;
  onLikePress?: (product: Product) => void;
  numColumns?: number;
}

export const ProductGrid: React.FC<ProductGridProps> = ({
  products,
  onProductPress,
  onLikePress,
  numColumns = 2,
}) => {
  const { width } = useWindowDimensions();
  const gap = 12;
  const padding = 16;
  const cardWidth = (width - padding * 2 - gap * (numColumns - 1)) / numColumns;

  const renderItem = ({ item, index }: { item: Product; index: number }) => (
    <Box
      width={cardWidth}
      marginLeft={index % numColumns === 0 ? 0 : gap}
      marginBottom={gap}
    >
      <ProductCard
        product={item}
        onPress={() => onProductPress?.(item)}
        onLikePress={() => onLikePress?.(item)}
      />
    </Box>
  );

  return (
    <FlatList
      data={products}
      renderItem={renderItem}
      keyExtractor={(item) => item.id}
      numColumns={numColumns}
      contentContainerStyle={{ padding }}
      showsVerticalScrollIndicator={false}
    />
  );
};
```

## Usage Example

```tsx
import { ProductGrid } from "@/components/ProductGrid";

const products: Product[] = [
  {
    id: "1",
    title: "Hand-knitted wool beanie, winter warm, multiple colors",
    imageUrl: "https://example.com/product1.jpg",
    currentPrice: 89.0,
    originalPrice: 129.0,
    tags: ["Free Shipping", "Best Seller"],
    seller: {
      id: "s1",
      name: "Handcraft Shop",
      avatarUrl: "https://example.com/seller1.jpg",
    },
    isLiked: false,
  },
  // ...more products
];

const ProductListScreen = () => {
  const handleProductPress = (product: Product) => {
    navigation.navigate("ProductDetail", { id: product.id });
  };

  const handleLikePress = (product: Product) => {
    // handle favorite logic
  };

  return (
    <ProductGrid
      products={products}
      onProductPress={handleProductPress}
      onLikePress={handleLikePress}
    />
  );
};
```

## Key Notes

1. **Image ratio**: fixed height 180, width 100%.
2. **Favorite button**: absolutely positioned top-right with semi-transparent background.
3. **Event isolation**: favorite button uses `stopPropagation` to avoid triggering the card press.
4. **Price display**: baseline alignment to mix different font sizes for the price.
5. **Strikethrough**: original price uses `textDecorationLine="line-through"`.
6. **Grid layout**: `FlatList` + `numColumns` for the masonry-style grid.
7. **Card width**: computed dynamically from screen width.
