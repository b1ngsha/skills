# Database Performance Rules

## Rule Index

| Rule ID  | Priority | Description                          |
| -------- | -------- | ------------------------------------ |
| perf-001 | P1       | Avoid N+1 queries                    |
| perf-002 | P2       | Use bulk operations                  |
| perf-003 | P2       | Use indexes appropriately            |
| perf-004 | P3       | Use only/defer to optimize           |
| perf-005 | P2       | Avoid querying inside loops          |
| perf-006 | P3       | Prefer exists() over count()         |
| perf-007 | P3       | Use transactions appropriately       |
| perf-008 | P3       | Use database functions               |

---

## perf-001: Avoid N+1 Queries

**Priority**: P1

**Rule**: Use `select_related` and `prefetch_related` to optimize related queries.

```python
# ❌ N+1 — 1 query + N queries
products = Product.objects.all()
for product in products:
    print(product.category.name)  # Queries category every iteration

# ✅ Correct — select_related (ForeignKey, OneToOne)
products = Product.objects.select_related('category').all()
for product in products:
    print(product.category.name)  # Single query

# ✅ Correct — prefetch_related (ManyToMany, reverse ForeignKey)
categories = Category.objects.prefetch_related('products').all()
for category in categories:
    print(category.products.all())  # Two queries total
```

---

## perf-002: Use Bulk Operations

**Priority**: P2

**Rule**: Replace per-row operations inside loops with bulk operations.

```python
# ❌ Inefficient — one-by-one create
for item in items:
    Product.objects.create(**item)  # N INSERTs

# ✅ Correct — bulk create
Product.objects.bulk_create([
    Product(**item) for item in items
], batch_size=1000)  # 1 INSERT (in batches)

# ❌ Inefficient — one-by-one update
for product in products:
    product.price = product.price * 1.1
    product.save()  # N UPDATEs

# ✅ Correct — bulk update
Product.objects.filter(category=category).update(
    price=F('price') * 1.1
)  # 1 UPDATE

# ✅ Correct — bulk_update
for product in products:
    product.price = product.price * 1.1

Product.objects.bulk_update(products, ['price'], batch_size=1000)
```

---

## perf-003: Use Indexes Appropriately

**Priority**: P2

**Rule**: Add indexes on frequently queried fields.

```python
class Product(models.Model):
    name = models.CharField(max_length=100, db_index=True)  # Single-field index
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    status = models.CharField(max_length=20)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            # Composite index — common combined queries
            models.Index(fields=['category', 'status']),
            models.Index(fields=['-created_at']),  # Descending index

            # Partial index — only indexes a subset
            models.Index(
                fields=['status'],
                name='active_products_idx',
                condition=models.Q(status='active')
            ),
        ]

# Check whether the query uses an index
from django.db import connection
Product.objects.filter(category_id=1, status='active')
print(connection.queries[-1])  # Inspect SQL
# Use EXPLAIN for analysis
```

---

## perf-004: Use only/defer to Optimize

**Priority**: P3

**Rule**: Query only the fields you need to reduce data transfer.

```python
# ❌ Loads every field
products = Product.objects.all()

# ✅ Load only required fields
products = Product.objects.only('id', 'name', 'price')

# ✅ Defer large fields
products = Product.objects.defer('description', 'content')

# ✅ Use values/values_list for dicts/tuples
product_names = Product.objects.values_list('name', flat=True)
product_data = Product.objects.values('id', 'name', 'price')
```

---

## perf-005: Avoid Querying Inside Loops

**Priority**: P2

**Rule**: Move queries out of loops.

```python
# ❌ Query inside loop
def process_orders(order_ids: list[int]):
    for order_id in order_ids:
        order = Order.objects.get(id=order_id)  # N queries
        process(order)

# ✅ Single query, iterate results
def process_orders(order_ids: list[int]):
    orders = Order.objects.filter(id__in=order_ids)
    for order in orders:
        process(order)

# ✅ Use in_bulk for a dict
def process_orders(order_ids: list[int]):
    orders = Order.objects.in_bulk(order_ids)
    for order_id in order_ids:
        if order_id in orders:
            process(orders[order_id])
```

---

## perf-006: Prefer exists() over count()

**Priority**: P3

**Rule**: When only checking existence, prefer `exists()` for efficiency.

```python
# ❌ Inefficient — count() scans all matching rows
if Product.objects.filter(category=category).count() > 0:
    do_something()

# ✅ Efficient — exists() returns on first match
if Product.objects.filter(category=category).exists():
    do_something()

# ❌ Inefficient
products = Product.objects.filter(category=category)
if len(products) > 0:  # Loads all data
    do_something()

# ✅ Efficient
if products.exists():
    do_something()
```

---

## perf-007: Use Transactions Appropriately

**Priority**: P3

**Rule**: Use transactions for consistency, but avoid long-running transactions.

```python
from django.db import transaction

# ✅ Decorator
@transaction.atomic
def transfer_money(from_account: Account, to_account: Account, amount: Decimal):
    from_account.balance -= amount
    from_account.save()
    to_account.balance += amount
    to_account.save()

# ✅ Context manager
def complex_operation():
    # Non-transactional work (e.g., logging)
    logger.info("Starting operation")

    with transaction.atomic():
        # Transactional work
        do_database_work()

    # Post-transaction work
    send_notification()

# ✅ Savepoint for partial rollback
def process_items(items):
    with transaction.atomic():
        for item in items:
            sid = transaction.savepoint()
            try:
                process_item(item)
            except ProcessError:
                transaction.savepoint_rollback(sid)
                # Continue with the next item
            else:
                transaction.savepoint_commit(sid)
```

---

## perf-008: Use Database Functions

**Priority**: P3

**Rule**: Push computation into the database to reduce data transfer.

```python
from django.db.models import Count, Sum, Avg, F, Value
from django.db.models.functions import Concat, Lower, Coalesce

# ✅ Aggregation
stats = Order.objects.aggregate(
    total=Sum('amount'),
    avg=Avg('amount'),
    count=Count('id')
)

# ✅ Group-by
category_stats = Product.objects.values('category').annotate(
    product_count=Count('id'),
    avg_price=Avg('price')
)

# ✅ F expressions
Product.objects.filter(stock__lt=F('min_stock'))

# ✅ Database functions
User.objects.annotate(
    full_name=Concat('first_name', Value(' '), 'last_name'),
    email_lower=Lower('email')
)

# ✅ NULL handling
Product.objects.annotate(
    final_price=Coalesce('sale_price', 'price')
)
```
