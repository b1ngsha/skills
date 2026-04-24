# Node Splitting Strategy

## Splitting Principles

### 1. Token Budget

Keep the data size of a single Figma node within an acceptable range:

| Complexity   | Suggested Children | Estimated Tokens |
| ------------ | ------------------ | ---------------- |
| Simple       | < 10 elements      | < 2K             |
| Medium       | 10-30 elements     | 2K-5K            |
| Complex      | 30-50 elements     | 5K-10K           |
| Must split   | > 50 elements      | > 10K ⚠️         |

### 2. Functional Boundaries

Split by functional boundary. Each node should be:

- An independent functional unit
- Testable and reusable in isolation
- Has clearly defined inputs and outputs

### 3. Reuse First

Identify reusable components and fetch only one instance:

```
Wrong: fetch the entire product list (10 cards)
Right: fetch only 1 ProductCard
```

## Splitting Checklist

### Must Split

- [ ] Page has multiple functional regions (Header + Content + Footer)
- [ ] Repeating list item components exist
- [ ] Deep nested structure (> 3 levels)
- [ ] Single region has too many elements (> 30)

### Can Be Combined

- [ ] Simple button group (< 5 buttons)
- [ ] Simple icon + text combos
- [ ] Single-purpose small components

## Splitting Examples

### Example 1: E-commerce Home

**Original page structure**:

```
HomePage
├── Header (Logo + Search + Cart)
├── Banner (carousel of 5 images)
├── Categories (8 category entries)
├── FlashSale (countdown + 3 products)
├── Recommend (title + 6 product cards)
└── TabBar (5 nav items)
```

**Splitting plan**:

```
Node 1: Header
Node 2: BannerCarousel (fetch structure only, use placeholders for images)
Node 3: CategoryGrid (8 entries)
Node 4: FlashSaleSection
Node 5: ProductCard (fetch only 1)
Node 6: TabBar
```

### Example 2: Profile Page

**Original page structure**:

```
ProfilePage
├── UserHeader (avatar + nickname + level)
├── StatsBar (following / followers / likes)
├── OrderSection (4 order entries)
├── ServiceSection (8 service entries)
├── SettingsSection (6 settings items)
└── LogoutButton
```

**Splitting plan**:

```
Node 1: UserHeader
Node 2: StatsBar
Node 3: OrderSection
Node 4: MenuSection (services + settings reuse the same component)
Node 5: ActionButton (logout)
```

## Node Fetch Order

Recommended fetch order:

1. **Base components** - widely reused (Card, Button, Input)
2. **Layout components** - Header, Footer, TabBar
3. **Content components** - functional sections
4. **Page container** - assembled last

## Figma Node URL Guide

Tell the user how to obtain a node URL:

1. Select the target node in Figma
2. Right-click → "Copy link to selection"
3. URL format: `https://www.figma.com/file/[fileId]/[fileName]?node-id=[nodeId]`

Or:

1. Select the node
2. Right panel → "Inspect" tab
3. Copy the "Link" field
