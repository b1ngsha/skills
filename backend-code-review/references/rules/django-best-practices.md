# Django Best Practices

## Rule Index

| Rule ID | Priority | Description                                |
| ------- | -------- | ------------------------------------------ |
| dj-002  | P3       | Use `get_object_or_404`                    |
| dj-003  | P2       | Foreign keys must specify `on_delete`      |
| dj-004  | P3       | Use `related_name`                         |
| dj-005  | P2       | Avoid `null=True` on CharField             |
| dj-006  | P3       | Use F() expressions for field updates      |
| dj-007  | P3       | Separate settings files                    |
| dj-008  | P2       | Use timezone-aware datetimes               |

---

## dj-002: Use `get_object_or_404`

**Priority**: P3

**Rule**: Use `get_object_or_404` instead of try/except when fetching a single object.

```python
# ❌ Incorrect
def get_product(request, pk):
    try:
        product = Product.objects.get(pk=pk)
    except Product.DoesNotExist:
        return HttpResponseNotFound()
    return render(request, 'product.html', {'product': product})

# ✅ Correct
from django.shortcuts import get_object_or_404

def get_product(request, pk):
    product = get_object_or_404(Product, pk=pk)
    return render(request, 'product.html', {'product': product})
```

---

## dj-003: Foreign Keys Must Specify `on_delete`

**Priority**: P2

**Rule**: Foreign keys must explicitly set `on_delete`, with the strategy chosen by business intent.

```python
# Strategy guide
on_delete=models.CASCADE     # Cascade delete (use cautiously)
on_delete=models.PROTECT     # Block deletion (recommended for important relations)
on_delete=models.SET_NULL    # Set to NULL (requires null=True)
on_delete=models.SET_DEFAULT # Set to default (requires default=...)
on_delete=models.DO_NOTHING  # Do nothing (requires DB-level constraint)
```

```python
# ✅ Example
class Order(models.Model):
    # When the user is deleted, keep the order and set user to NULL
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='orders'
    )

    # Block product deletion (orders depend on the product)
    product = models.ForeignKey(
        Product,
        on_delete=models.PROTECT,
        related_name='orders'
    )
```

---

## dj-004: Use `related_name`

**Priority**: P3

**Rule**: Foreign key and many-to-many fields should set `related_name` for cleaner reverse queries.

```python
# ❌ Not recommended
class Comment(models.Model):
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    # Reverse query: post.comment_set.all()

# ✅ Recommended
class Comment(models.Model):
    post = models.ForeignKey(
        Post,
        on_delete=models.CASCADE,
        related_name='comments'  # Reverse query: post.comments.all()
    )
```

---

## dj-005: Avoid `null=True` on CharField

**Priority**: P2

**Rule**: Use empty string instead of NULL for CharField/TextField empty values.

```python
# ❌ Incorrect — two "empty" states: NULL and ''
class Product(models.Model):
    description = models.CharField(max_length=500, null=True, blank=True)

# ✅ Correct — single "empty" state: ''
class Product(models.Model):
    description = models.CharField(max_length=500, blank=True, default='')
```

**Exception**: When you must distinguish "not filled in" from "filled in as empty", `null=True` is acceptable.

---

## dj-006: Use F() Expressions for Field Updates

**Priority**: P3

**Rule**: When updating a field based on its current value, use F() expressions to avoid race conditions.

```python
from django.db.models import F

# ❌ Incorrect — race condition
product = Product.objects.get(pk=1)
product.view_count = product.view_count + 1
product.save()

# ✅ Correct — atomic operation
Product.objects.filter(pk=1).update(view_count=F('view_count') + 1)

# Or
product = Product.objects.get(pk=1)
product.view_count = F('view_count') + 1
product.save(update_fields=['view_count'])
```

---

## dj-007: Separate Settings Files

**Priority**: P3

**Rule**: Manage environments via separate settings files.

```
config/
├── __init__.py
├── base.py          # Base settings
├── development.py   # Development
├── production.py    # Production
└── testing.py       # Testing
```

```python
# settings.py
from .config import *  # noqa: F401, F403

# Or select via environment variable
import os
env = os.environ.get('DJANGO_ENV', 'development')
if env == 'production':
    from .config.production import *
else:
    from .config.development import *
```

---

## dj-008: Use Timezone-Aware Datetimes

**Priority**: P2

**Rule**: Always use Django's timezone module for datetime handling.

```python
# ❌ Incorrect — naive datetime
from datetime import datetime
now = datetime.now()

# ✅ Correct — timezone-aware
from django.utils import timezone
now = timezone.now()

# In a Model
class Event(models.Model):
    # Auto timezone-aware
    created_at = models.DateTimeField(auto_now_add=True)

    # Manual default value
    scheduled_at = models.DateTimeField(default=timezone.now)
```
