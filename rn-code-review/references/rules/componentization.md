# Componentization Rules

## Rule Overview

| Rule ID  | Priority | Description                                  |
| -------- | -------- | -------------------------------------------- |
| comp-001 | P1       | Detect duplicated code, suggest componentize |
| comp-002 | P2       | Check whether component granularity is right |
| comp-003 | P2       | Check whether a component needs its own file |
| comp-004 | P3       | Check Props design                           |
| comp-005 | P3       | Check single-responsibility                  |

---

## comp-001: Duplicated Code Detection

**Priority**: P1 (high)

### Description

The same or similar JSX structure appears ≥2 times. Extract it into a standalone component.

### Pattern

```tsx
// ❌ problem: duplicated card structure
<Box className="p-4 bg-white rounded-lg">
  <Image source={{ uri: item1.image }} className="w-full h-40" />
  <Text className="text-lg font-semibold">{item1.title}</Text>
  <Text className="text-gray-500">{item1.description}</Text>
</Box>

<Box className="p-4 bg-white rounded-lg">
  <Image source={{ uri: item2.image }} className="w-full h-40" />
  <Text className="text-lg font-semibold">{item2.title}</Text>
  <Text className="text-gray-500">{item2.description}</Text>
</Box>
```

### Recommended Fix

```tsx
// ✅ extract to a component
interface ItemCardProps {
  item: { image: string; title: string; description: string };
}

const ItemCard: React.FC<ItemCardProps> = ({ item }) => (
  <Box className="p-4 bg-white rounded-lg">
    <Image source={{ uri: item.image }} className="w-full h-40" />
    <Text className="text-lg font-semibold">{item.title}</Text>
    <Text className="text-gray-500">{item.description}</Text>
  </Box>
);

// usage
<ItemCard item={item1} />
<ItemCard item={item2} />
```

---

## comp-002: Granularity Check

**Priority**: P2 (medium)

### Description

- **Over-componentization**: a 3–5-line trivial structure should not be its own component.
- **Under-componentization**: a single component's JSX exceeding 150 lines should be split.

### Pattern

```tsx
// ❌ over-componentization: too trivial
const Divider = () => <Box className="h-px bg-gray-200" />;
const Spacer = () => <Box className="h-4" />;

// ❌ under-componentization: single component too large
const HomePage = () => {
  return <ScrollView>{/* 200+ lines of JSX */}</ScrollView>;
};
```

### Recommended Fix

```tsx
// ✅ inline trivial structures
<Box className="h-px bg-gray-200 my-4" />;

// ✅ split large components
const HomePage = () => {
  return (
    <ScrollView className="flex-1">
      <HeroSection />
      <CategorySection />
      <ProductSection />
      <FooterSection />
    </ScrollView>
  );
};
```

### Granularity Reference

| Lines     | Suggestion                       |
| --------- | -------------------------------- |
| < 10      | inline unless reused             |
| 10–50     | depends on reuse                 |
| 50–100    | should componentize              |
| > 100     | must split                       |

---

## comp-003: File Location Check

**Priority**: P2 (medium)

### Description

A component should live in the right place based on its reuse scope.

### Decision Rules

| Reuse Scope                        | File Location           |
| ---------------------------------- | ----------------------- |
| Across multiple pages/features     | `components/shared/`    |
| Multiple places within one feature | `components/[feature]/` |
| Only used in current file          | inside the current file |

### Pattern

```tsx
// ❌ problem: shared component defined inside a page file
// screens/Home.tsx
const Avatar = ({ uri }) => { ... };  // but Profile.tsx also uses it

// ❌ problem: single-use component lives in shared/
// components/shared/HomeHeroBanner.tsx  // only Home uses it
```

### Recommended Fix

```tsx
// ✅ shared component goes to shared/
// components/shared/Avatar.tsx
export const Avatar = ({ uri }) => { ... };

// ✅ single-page component lives in the feature dir or current file
// components/home/HeroBanner.tsx
// or defined inside screens/Home.tsx
```

---

## comp-004: Props Design Check

**Priority**: P3 (medium)

### Description

Component Props should be clear, cohesive, and easy to use.

### Pattern

```tsx
// ❌ problem 1: too many Props, exploded an object
interface ProductCardProps {
  id: string;
  title: string;
  price: number;
  image: string;
  description: string;
  category: string;
  rating: number;
  reviewCount: number;
  inStock: boolean;
  // ... 10+ props
}

// ❌ problem 2: missing Props interface
const ProductCard = ({ product, onPress }) => { ... };

// ❌ problem 3: poor naming
interface Props {
  data: any;        // unclear
  cb: () => void;   // vague
}
```

### Recommended Fix

```tsx
// ✅ aggregate related properties
interface ProductCardProps {
  product: Product;
  onPress: (id: string) => void;
  variant?: 'compact' | 'full';
}

// ✅ explicit Props interface
interface ProductCardProps { ... }
const ProductCard: React.FC<ProductCardProps> = ({ product, onPress }) => { ... };

// ✅ proper naming
interface ProductCardProps {
  product: Product;           // explicit name
  onPress: () => void;        // on-prefixed callback
  onAddToCart?: () => void;   // optional callback
}
```

### Props Design Checklist

- [ ] Are Props between 3 and 7?
- [ ] Is there a Props interface defined?
- [ ] Do callbacks use the `on` prefix?
- [ ] Are `any` types avoided?
- [ ] Do optional Props have reasonable defaults?

---

## comp-005: Single Responsibility

**Priority**: P3 (medium)

### Description

A component should do one thing. Don't mix presentation and business logic.

### Pattern

```tsx
// ❌ problem: component contains API calls and complex business logic
const ProductCard = ({ productId }) => {
  const [product, setProduct] = useState(null);
  const [cart, setCart] = useState([]);

  useEffect(() => {
    fetch(`/api/products/${productId}`).then(...);
  }, [productId]);

  const handleAddToCart = async () => {
    await fetch('/api/cart/add', ...);
    trackEvent('add_to_cart', ...);
    showToast('Added');
    // complex business logic
  };

  return ( ... );
};
```

### Recommended Fix

```tsx
// ✅ separate concerns

// 1. presentational component (pure UI)
interface ProductCardProps {
  product: Product;
  onAddToCart: () => void;
}
const ProductCard: React.FC<ProductCardProps> = ({ product, onAddToCart }) => (
  <Box>
    <Text>{product.title}</Text>
    <Button onPress={onAddToCart}>Add to cart</Button>
  </Box>
);

// 2. container component / hook (business logic)
const useProduct = (productId: string) => {
  // API logic
};

const useCart = () => {
  // cart logic
};

// 3. page assembly
const ProductPage = ({ productId }) => {
  const { product } = useProduct(productId);
  const { addToCart } = useCart();

  return (
    <ProductCard product={product} onAddToCart={() => addToCart(product)} />
  );
};
```

---

## Review Output Example

```markdown
## 🟡 Componentization Issues (3 issues)

### [comp-001] Duplicated code should be componentized

- **File**: `screens/Home.tsx:45-60, 78-93`
- **Issue**: product card structure duplicated 2 times
- **Suggestion**: extract into a `ProductCard` component
- **Location**: since `ProductList.tsx` uses a similar structure, place it at `components/product/ProductCard.tsx`

### [comp-002] Component granularity too large

- **File**: `screens/Profile.tsx`
- **Issue**: component JSX is 187 lines, exceeds the recommended 100-line cap
- **Suggestion**: split into `ProfileHeader`, `ProfileStats`, `ProfileSettings`, etc.

### [comp-003] Component placement incorrect

- **File**: `screens/Home.tsx:12-25`
- **Issue**: `Avatar` defined in Home.tsx but `Profile.tsx` and `Settings.tsx` also use it
- **Suggestion**: move to `components/shared/Avatar.tsx`
```
