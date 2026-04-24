# Screenshot Analysis Method

## Analysis Flow

### 1. Identify Overall Layout

First, recognize the overall layout pattern of the page:

| Layout            | Characteristic            | Common Use Case             |
| ----------------- | ------------------------- | --------------------------- |
| Vertical scroll   | Content stacked top-down  | Detail page, article page   |
| Grid              | Multi-column card layout  | Product list, image grid    |
| Tab               | Bottom/top navigation bar | Home, main shell            |
| Drawer            | Side navigation           | Admin dashboard             |
| Form              | Vertical input fields     | Login, signup, edit screens |

### 2. Partition by Functional Area

Split the page into independent functional regions:

```
┌─────────────────────────────┐
│         Header              │  ← Fixed header
├─────────────────────────────┤
│                             │
│      Content Area           │  ← Scrollable content
│                             │
├─────────────────────────────┤
│         Footer              │  ← Fixed footer (optional)
└─────────────────────────────┘
```

### 3. Component Identification Checklist

- [ ] Is there a fixed Header?
- [ ] Is there a bottom TabBar?
- [ ] Is there a floating action button (FAB)?
- [ ] Is there a list or grid?
- [ ] Are list items reusable?
- [ ] Is there a form input area?
- [ ] Are there modals or dialogs?
- [ ] Are there carousels or horizontal scrollers?

### 4. Node Naming Conventions

| Component Type | Naming Pattern     | Example        |
| -------------- | ------------------ | -------------- |
| Page container | `[Feature]Screen`  | `HomeScreen`   |
| Header         | `[Page]Header`     | `HomeHeader`   |
| List item      | `[Item]Card`       | `ProductCard`  |
| Form           | `[Action]Form`     | `LoginForm`    |
| Button group   | `[Feature]Actions` | `CartActions`  |
| Tab bar        | `[Type]Tabs`       | `CategoryTabs` |

## Output Format

```markdown
## Page Analysis

**Page name**: [inferred from screenshot]
**Layout pattern**: [vertical scroll / grid / tab / ...]
**Estimated nodes**: [N]

### Hierarchy

[PageName]Screen
├── Node 1: [ComponentName]
│ ├── Contains: [child element list]
│ └── Note: [whether it needs its own fetch]
├── Node 2: [ComponentName]
│ ├── Contains: [child element list]
│ └── Note: [whether it needs its own fetch]
...

### Suggested Fetch Order

1. [ComponentName] - [reason]
2. [ComponentName] - [reason]
   ...

### Reusable Components

- [ComponentName] appears N times in the page; fetch only one instance.
```

## Complex Scenarios

### Scenario 1: Long List Page

```
ProductListScreen
├── Node 1: SearchHeader
├── Node 2: FilterBar
├── Node 3: ProductCard (fetch only 1)
│   └── Note: list item reused for every product
└── Node 4: LoadMoreFooter
```

### Scenario 2: Complex Form Page

```
RegisterScreen
├── Node 1: FormHeader
├── Node 2: AvatarUploader
├── Node 3: BasicInfoForm
│   └── Contains: name, phone, email inputs
├── Node 4: AddressForm
│   └── Contains: region picker, detailed address
└── Node 5: SubmitActions
```

### Scenario 3: Tab Page

```
MainTabScreen
├── Node 1: BottomTabBar (shared component)
└── Node 2-N: each tab page handled separately
    └── Note: analyze each tab page independently
```
