# Complete Example: Form Component

## Figma Design Description

```
LoginForm component
├── Header
│   ├── Title (Sign In)
│   └── Subtitle (Welcome back)
├── FormFields
│   ├── PhoneInput
│   ├── PasswordInput (with show/hide toggle)
│   └── RememberMe (checkbox)
├── Actions
│   ├── LoginButton (primary)
│   └── ForgotPassword (link)
└── Divider
    ├── Line
    ├── Text (Other sign-in methods)
    └── Line
└── SocialLogin
    ├── WechatButton
    └── AppleButton
```

## Generated Code

### types/auth.ts

```typescript
export interface LoginFormData {
  phone: string;
  password: string;
  rememberMe: boolean;
}

export interface LoginFormProps {
  onSubmit: (data: LoginFormData) => Promise<void>;
  onForgotPassword?: () => void;
  onWechatLogin?: () => void;
  onAppleLogin?: () => void;
}
```

### components/LoginForm.tsx

```tsx
import React, { useState } from "react";
import {
  Box,
  VStack,
  HStack,
  Text,
  Heading,
  Input,
  InputField,
  InputSlot,
  InputIcon,
  Button,
  ButtonText,
  ButtonSpinner,
  Checkbox,
  CheckboxIndicator,
  CheckboxIcon,
  CheckboxLabel,
  Pressable,
  Divider,
} from "@/components/ui";
import { Phone, Lock, Eye, EyeOff, Check } from "lucide-react-native";
import type { LoginFormProps, LoginFormData } from "@/types/auth";

export const LoginForm: React.FC<LoginFormProps> = ({
  onSubmit,
  onForgotPassword,
  onWechatLogin,
  onAppleLogin,
}) => {
  const [formData, setFormData] = useState<LoginFormData>({
    phone: "",
    password: "",
    rememberMe: false,
  });
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errors, setErrors] = useState<
    Partial<Record<keyof LoginFormData, string>>
  >({});

  const validate = (): boolean => {
    const newErrors: typeof errors = {};

    if (!formData.phone) {
      newErrors.phone = "Please enter your phone number";
    } else if (!/^1[3-9]\d{9}$/.test(formData.phone)) {
      newErrors.phone = "Invalid phone number format";
    }

    if (!formData.password) {
      newErrors.password = "Please enter your password";
    } else if (formData.password.length < 6) {
      newErrors.password = "Password must be at least 6 characters";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;

    setIsLoading(true);
    try {
      await onSubmit(formData);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <VStack space="xl" p="$6">
      {/* Title */}
      <VStack space="xs" alignItems="center" mb="$4">
        <Heading size="2xl">Sign In</Heading>
        <Text size="md" color="$textLight500">
          Welcome back
        </Text>
      </VStack>

      {/* Form */}
      <VStack space="lg">
        {/* Phone */}
        <VStack space="xs">
          <Input size="lg" variant="outline" isInvalid={!!errors.phone}>
            <InputSlot pl="$3">
              <InputIcon as={Phone} color="$textLight400" />
            </InputSlot>
            <InputField
              placeholder="Enter your phone number"
              keyboardType="phone-pad"
              value={formData.phone}
              onChangeText={(value) => {
                setFormData((prev) => ({ ...prev, phone: value }));
                if (errors.phone)
                  setErrors((prev) => ({ ...prev, phone: undefined }));
              }}
              maxLength={11}
            />
          </Input>
          {errors.phone && (
            <Text size="sm" color="$error500">
              {errors.phone}
            </Text>
          )}
        </VStack>

        {/* Password */}
        <VStack space="xs">
          <Input size="lg" variant="outline" isInvalid={!!errors.password}>
            <InputSlot pl="$3">
              <InputIcon as={Lock} color="$textLight400" />
            </InputSlot>
            <InputField
              placeholder="Enter your password"
              type={showPassword ? "text" : "password"}
              value={formData.password}
              onChangeText={(value) => {
                setFormData((prev) => ({ ...prev, password: value }));
                if (errors.password)
                  setErrors((prev) => ({ ...prev, password: undefined }));
              }}
            />
            <InputSlot pr="$3">
              <Pressable onPress={() => setShowPassword(!showPassword)}>
                <InputIcon
                  as={showPassword ? Eye : EyeOff}
                  color="$textLight400"
                />
              </Pressable>
            </InputSlot>
          </Input>
          {errors.password && (
            <Text size="sm" color="$error500">
              {errors.password}
            </Text>
          )}
        </VStack>

        {/* Remember me & forgot password */}
        <HStack justifyContent="space-between" alignItems="center">
          <Checkbox
            value="remember"
            isChecked={formData.rememberMe}
            onChange={(isChecked) =>
              setFormData((prev) => ({ ...prev, rememberMe: isChecked }))
            }
          >
            <CheckboxIndicator mr="$2">
              <CheckboxIcon as={Check} />
            </CheckboxIndicator>
            <CheckboxLabel>Remember me</CheckboxLabel>
          </Checkbox>

          <Pressable onPress={onForgotPassword}>
            <Text size="sm" color="$primary500">
              Forgot password?
            </Text>
          </Pressable>
        </HStack>
      </VStack>

      {/* Login button */}
      <Button
        size="lg"
        action="primary"
        onPress={handleSubmit}
        isDisabled={isLoading}
      >
        {isLoading ? (
          <>
            <ButtonSpinner mr="$2" />
            <ButtonText>Signing in...</ButtonText>
          </>
        ) : (
          <ButtonText>Sign In</ButtonText>
        )}
      </Button>

      {/* Divider */}
      <HStack alignItems="center" space="md">
        <Divider flex={1} />
        <Text size="sm" color="$textLight400">
          Other sign-in methods
        </Text>
        <Divider flex={1} />
      </HStack>

      {/* Social login */}
      <HStack space="lg" justifyContent="center">
        <Pressable
          onPress={onWechatLogin}
          bg="$success500"
          p="$3"
          borderRadius="$full"
          $active={{ opacity: 0.8 }}
        >
          {/* WeChat icon */}
          <Box
            width={24}
            height={24}
            alignItems="center"
            justifyContent="center"
          >
            <Text color="$white" fontWeight="$bold">
              W
            </Text>
          </Box>
        </Pressable>

        <Pressable
          onPress={onAppleLogin}
          bg="$black"
          p="$3"
          borderRadius="$full"
          $active={{ opacity: 0.8 }}
        >
          {/* Apple icon */}
          <Box
            width={24}
            height={24}
            alignItems="center"
            justifyContent="center"
          >
            <Text color="$white" fontWeight="$bold">
              A
            </Text>
          </Box>
        </Pressable>
      </HStack>
    </VStack>
  );
};
```

### screens/LoginScreen.tsx

```tsx
import React from "react";
import { KeyboardAvoidingView, Platform, ScrollView } from "react-native";
import { Box } from "@/components/ui";
import { LoginForm } from "@/components/LoginForm";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import type { LoginFormData } from "@/types/auth";

export const LoginScreen: React.FC = () => {
  const insets = useSafeAreaInsets();

  const handleLogin = async (data: LoginFormData) => {
    // call login API
    console.log("Login:", data);
  };

  return (
    <Box flex={1} bg="$white">
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        style={{ flex: 1 }}
      >
        <ScrollView
          contentContainerStyle={{
            flexGrow: 1,
            justifyContent: "center",
            paddingTop: insets.top,
            paddingBottom: insets.bottom,
          }}
          keyboardShouldPersistTaps="handled"
        >
          <LoginForm
            onSubmit={handleLogin}
            onForgotPassword={() => {
              /* navigate to forgot password */
            }}
            onWechatLogin={() => {
              /* WeChat login */
            }}
            onAppleLogin={() => {
              /* Apple login */
            }}
          />
        </ScrollView>
      </KeyboardAvoidingView>
    </Box>
  );
};
```

## Key Notes

1. **Keyboard handling**: use `KeyboardAvoidingView` to prevent keyboard overlap.
2. **Form validation**: client-side validation + inline error messages.
3. **Password visibility**: toggle via the `type` prop.
4. **Loading state**: disable the button and show a spinner.
5. **Social login**: round buttons with icons.
6. **Divider**: `HStack` + `Divider` + `Text`.
