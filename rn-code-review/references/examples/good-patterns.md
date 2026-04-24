# Recommended Patterns

This document collects validated code patterns you can reference directly.

## 1. Complete List Component

```tsx
import { memo, useCallback, useMemo } from "react";
import { FlatList, type ListRenderItem } from "react-native";
import { Box, Text, Pressable, VStack, HStack } from "@/components/ui";
import { Image } from "expo-image";
import type { Product } from "../types";

interface ProductListProps {
  products: Product[];
  onProductPress: (id: string) => void;
}

export const ProductList = memo(
  ({ products, onProductPress }: ProductListProps) => {
    // stable keyExtractor
    const keyExtractor = useCallback((item: Product) => item.id, []);

    // stable renderItem
    const renderItem: ListRenderItem<Product> = useCallback(
      ({ item }) => <ProductCard product={item} onPress={onProductPress} />,
      [onProductPress]
    );

    // fixed-height layout
    const getItemLayout = useCallback(
      (_: unknown, index: number) => ({
        length: ITEM_HEIGHT,
        offset: ITEM_HEIGHT * index,
        index,
      }),
      []
    );

    return (
      <FlatList
        data={products}
        keyExtractor={keyExtractor}
        renderItem={renderItem}
        getItemLayout={getItemLayout}
        initialNumToRender={10}
        maxToRenderPerBatch={10}
        windowSize={5}
        removeClippedSubviews
        showsVerticalScrollIndicator={false}
      />
    );
  }
);

const ITEM_HEIGHT = 120;

// child component also memoized
interface ProductCardProps {
  product: Product;
  onPress: (id: string) => void;
}

const ProductCard = memo(({ product, onPress }: ProductCardProps) => {
  const handlePress = useCallback(() => {
    onPress(product.id);
  }, [onPress, product.id]);

  return (
    <Pressable
      onPress={handlePress}
      accessibilityRole="button"
      accessibilityLabel={`View product: ${product.name}`}
    >
      <HStack space="md" p="$3" bg="$white" borderRadius="$lg">
        <Image
          source={{ uri: product.imageUrl }}
          style={{ width: 80, height: 80, borderRadius: 8 }}
          contentFit="cover"
          placeholder={product.blurhash}
          transition={200}
        />
        <VStack flex={1} justifyContent="center">
          <Text size="md" fontWeight="$semibold" numberOfLines={2}>
            {product.name}
          </Text>
          <Text size="lg" color="$primary500" fontWeight="$bold">
            ¥{product.price}
          </Text>
        </VStack>
      </HStack>
    </Pressable>
  );
});
```

## 2. Data Fetching with Cleanup

```tsx
import { useEffect, useState, useCallback } from "react";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useQuery } from "@tanstack/react-query";
import {
  Box,
  VStack,
  Text,
  Spinner,
  Button,
  ButtonText,
} from "@/components/ui";
import type { User } from "../types";
import { fetchUser } from "../api";

interface ProfileScreenProps {
  userId: string;
}

export const ProfileScreen = ({ userId }: ProfileScreenProps) => {
  const insets = useSafeAreaInsets();

  // react-query handles cancellation and caching automatically
  const {
    data: user,
    isLoading,
    error,
    refetch,
  } = useQuery({
    queryKey: ["user", userId],
    queryFn: () => fetchUser(userId),
    staleTime: 5 * 60 * 1000, // do not refetch within 5 minutes
  });

  if (isLoading) {
    return (
      <Box flex={1} justifyContent="center" alignItems="center">
        <Spinner size="large" />
      </Box>
    );
  }

  if (error) {
    return (
      <Box flex={1} justifyContent="center" alignItems="center" p="$4">
        <Text color="$error500">Load failed</Text>
        <Button onPress={() => refetch()} mt="$4">
          <ButtonText>Retry</ButtonText>
        </Button>
      </Box>
    );
  }

  return (
    <Box flex={1} pt={insets.top} pb={insets.bottom}>
      <VStack p="$4" space="md">
        <Text size="2xl" fontWeight="$bold">
          {user?.name}
        </Text>
        <Text color="$textLight500">{user?.email}</Text>
      </VStack>
    </Box>
  );
};
```

## 3. Form Handling

```tsx
import { useCallback } from "react";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { KeyboardAvoidingView, Platform, ScrollView } from "react-native";
import {
  Box,
  VStack,
  FormControl,
  FormControlLabel,
  FormControlLabelText,
  FormControlError,
  FormControlErrorText,
  Input,
  InputField,
  Button,
  ButtonText,
} from "@/components/ui";

// validation schema
const loginSchema = z.object({
  email: z.string().email("Please enter a valid email"),
  password: z.string().min(6, "Password must be at least 6 characters"),
});

type LoginFormData = z.infer<typeof loginSchema>;

interface LoginFormProps {
  onSubmit: (data: LoginFormData) => Promise<void>;
}

export const LoginForm = ({ onSubmit }: LoginFormProps) => {
  const {
    control,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  });

  const onSubmitForm = useCallback(
    async (data: LoginFormData) => {
      await onSubmit(data);
    },
    [onSubmit]
  );

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === "ios" ? "padding" : "height"}
    >
      <ScrollView
        contentContainerStyle={{ flexGrow: 1, justifyContent: "center" }}
        keyboardShouldPersistTaps="handled"
      >
        <Box p="$6">
          <VStack space="lg">
            <FormControl isInvalid={!!errors.email}>
              <FormControlLabel>
                <FormControlLabelText>Email</FormControlLabelText>
              </FormControlLabel>
              <Controller
                control={control}
                name="email"
                render={({ field: { onChange, onBlur, value } }) => (
                  <Input>
                    <InputField
                      value={value}
                      onChangeText={onChange}
                      onBlur={onBlur}
                      placeholder="Enter email"
                      keyboardType="email-address"
                      autoCapitalize="none"
                      autoComplete="email"
                    />
                  </Input>
                )}
              />
              <FormControlError>
                <FormControlErrorText>
                  {errors.email?.message}
                </FormControlErrorText>
              </FormControlError>
            </FormControl>

            <FormControl isInvalid={!!errors.password}>
              <FormControlLabel>
                <FormControlLabelText>Password</FormControlLabelText>
              </FormControlLabel>
              <Controller
                control={control}
                name="password"
                render={({ field: { onChange, onBlur, value } }) => (
                  <Input>
                    <InputField
                      value={value}
                      onChangeText={onChange}
                      onBlur={onBlur}
                      placeholder="Enter password"
                      secureTextEntry
                      autoComplete="password"
                    />
                  </Input>
                )}
              />
              <FormControlError>
                <FormControlErrorText>
                  {errors.password?.message}
                </FormControlErrorText>
              </FormControlError>
            </FormControl>

            <Button
              onPress={handleSubmit(onSubmitForm)}
              isDisabled={isSubmitting}
              size="lg"
            >
              <ButtonText>{isSubmitting ? "Signing in..." : "Sign in"}</ButtonText>
            </Button>
          </VStack>
        </Box>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};
```

## 4. Type-Safe Navigation

```tsx
import { useCallback } from "react";
import { useRouter, useLocalSearchParams } from "expo-router";
import type { Href } from "expo-router";

// route param types
interface ProductParams {
  id: string;
  source?: "home" | "search" | "category";
}

// type-safe router hook
export const useTypedRouter = () => {
  const router = useRouter();

  const navigateToProduct = useCallback(
    (params: ProductParams) => {
      const href: Href = {
        pathname: "/product/[id]",
        params: { id: params.id, source: params.source },
      };
      router.push(href);
    },
    [router]
  );

  const navigateToCategory = useCallback(
    (categoryId: string) => {
      router.push(`/category/${categoryId}` as Href);
    },
    [router]
  );

  return {
    navigateToProduct,
    navigateToCategory,
    goBack: router.back,
  };
};

// usage
const ProductScreen = () => {
  const { id, source } = useLocalSearchParams<ProductParams>();
  // id and source both have correct types
};
```

## 5. Responsive Layout

```tsx
import { useWindowDimensions, Platform } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Box, HStack, VStack } from "@/components/ui";

const BREAKPOINT_TABLET = 768;

export const ResponsiveLayout = ({
  children,
}: {
  children: React.ReactNode;
}) => {
  const { width, height } = useWindowDimensions();
  const insets = useSafeAreaInsets();

  const isTablet = width >= BREAKPOINT_TABLET;
  const isLandscape = width > height;

  // tablet: sidebar layout
  if (isTablet) {
    return (
      <HStack flex={1}>
        <Box
          w={280}
          bg="$backgroundLight50"
          pt={insets.top}
          pb={insets.bottom}
          pl={isLandscape ? insets.left : 0}
        >
          <Sidebar />
        </Box>
        <Box
          flex={1}
          pt={insets.top}
          pb={insets.bottom}
          pr={isLandscape ? insets.right : 0}
        >
          {children}
        </Box>
      </HStack>
    );
  }

  // phone: tab-bar layout
  return (
    <Box flex={1} pt={insets.top}>
      {children}
      <Box pb={insets.bottom}>
        <TabBar />
      </Box>
    </Box>
  );
};
```

## 6. Component with Animation Cleanup

```tsx
import { useEffect, useCallback } from "react";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  cancelAnimation,
  runOnJS,
} from "react-native-reanimated";
import { Pressable } from "react-native";
import { Box } from "@/components/ui";

interface AnimatedCardProps {
  isVisible: boolean;
  onAnimationComplete?: () => void;
}

export const AnimatedCard = ({
  isVisible,
  onAnimationComplete,
}: AnimatedCardProps) => {
  const opacity = useSharedValue(0);
  const translateY = useSharedValue(20);

  useEffect(() => {
    if (isVisible) {
      opacity.value = withSpring(1);
      translateY.value = withSpring(0, {}, (finished) => {
        if (finished && onAnimationComplete) {
          runOnJS(onAnimationComplete)();
        }
      });
    } else {
      opacity.value = withSpring(0);
      translateY.value = withSpring(20);
    }

    // cancel animations on unmount
    return () => {
      cancelAnimation(opacity);
      cancelAnimation(translateY);
    };
  }, [isVisible, opacity, translateY, onAnimationComplete]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }],
  }));

  return (
    <Animated.View style={animatedStyle}>
      <Box
        bg="$white"
        p="$4"
        borderRadius="$lg"
        shadowColor="$black"
        shadowOpacity={0.1}
      >
        {/* content */}
      </Box>
    </Animated.View>
  );
};
```
