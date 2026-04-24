# Backend Code Review Quick Checklist

## Per-File Review Guide

### Models (models.py)

```python
# ✅ Checks
class Product(models.Model):
    # 1. Field type appropriateness
    name = models.CharField(max_length=100)  # Is the length sufficient?
    price = models.DecimalField(max_digits=10, decimal_places=2)  # Correct precision?

    # 2. Foreign key on_delete strategy
    category = models.ForeignKey(
        Category,
        on_delete=models.PROTECT,  # If not CASCADE, confirm it is appropriate
        related_name='products'    # related_name set
    )

    # 3. Indexes
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    # 4. Meta configuration
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['category', 'status']),  # Composite index
        ]
        constraints = [
            models.CheckConstraint(check=models.Q(price__gte=0), name='price_positive'),
        ]
```

### Serializers (serializers.py)

> **Convention**: For non-pure-CRUD scenarios, use `serializers.Serializer`; define input/output separately.

```python
# ============================================================
# Output serializers (for responses)
# ============================================================

class ProductListSerializer(serializers.Serializer):
    """Product list response"""
    id = serializers.IntegerField()
    name = serializers.CharField()
    price = serializers.DecimalField(max_digits=10, decimal_places=2)
    category_name = serializers.CharField(source='category.name')


class ProductDetailSerializer(serializers.Serializer):
    """Product detail response"""
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    price = serializers.DecimalField(max_digits=10, decimal_places=2)
    stock = serializers.IntegerField()
    category = CategoryDetailSerializer()
    created_at = serializers.DateTimeField()


# ============================================================
# Input serializers (for request validation)
# ============================================================

class CreateProductSerializer(serializers.Serializer):
    """Create product request"""
    name = serializers.CharField(max_length=100)
    description = serializers.CharField(max_length=2000, required=False, default='')
    price = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('0.01'))
    category_id = serializers.IntegerField()
    stock = serializers.IntegerField(min_value=0)

    # 1. Single-field validation
    def validate_category_id(self, value: int) -> int:
        if not Category.objects.filter(id=value, is_active=True).exists():
            raise serializers.ValidationError("Category does not exist or is inactive")
        return value

    # 2. Cross-field validation
    def validate(self, attrs: dict) -> dict:
        # Cross-field validation logic
        return attrs


class UpdateProductSerializer(serializers.Serializer):
    """Update product request"""
    name = serializers.CharField(max_length=100, required=False)
    description = serializers.CharField(max_length=2000, required=False)
    price = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('0.01'), required=False)
    stock = serializers.IntegerField(min_value=0, required=False)
```

### Views (views.py)

> **Convention**: Use `generics.XxxView`; naming format `{Verb}{Entities}View`.

```python
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny


class ListProductsView(generics.ListAPIView):
    """Get product list"""
    # 1. Permissions
    permission_classes = [AllowAny]
    serializer_class = ProductListSerializer

    # 2. Optimize queries
    def get_queryset(self):
        return Product.objects.select_related('category').filter(is_active=True)


class RetrieveProductView(generics.RetrieveAPIView):
    """Get product detail"""
    permission_classes = [AllowAny]
    serializer_class = ProductDetailSerializer
    queryset = Product.objects.select_related('category')


class CreateProductView(generics.CreateAPIView):
    """Create product"""
    permission_classes = [IsAuthenticated]
    serializer_class = CreateProductSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # 3. Delegate to service layer
        product = ProductService.create_product(
            user=request.user,
            data=serializer.validated_data
        )

        return Response(
            ProductDetailSerializer(product).data,
            status=status.HTTP_201_CREATED
        )


class UpdateProductView(generics.UpdateAPIView):
    """Update product"""
    permission_classes = [IsAuthenticated, IsOwner]
    serializer_class = UpdateProductSerializer

    def get_queryset(self):
        return Product.objects.filter(seller=self.request.user)

    def update(self, request, *args, **kwargs):
        product = self.get_object()
        serializer = self.get_serializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        # 4. Exception handling
        try:
            product = ProductService.update_product(product, serializer.validated_data)
        except IntegrityError:
            raise ValidationError({'detail': 'Data conflict'})

        return Response(ProductDetailSerializer(product).data)
```

### URLs (urls.py)

```python
# ✅ Checks: use path + View instead of router + ViewSet
urlpatterns = [
    # Products
    path('products/', ListProductsView.as_view(), name='product-list'),
    path('products/<int:pk>/', RetrieveProductView.as_view(), name='product-detail'),
    path('products/create/', CreateProductView.as_view(), name='product-create'),
    path('products/<int:pk>/update/', UpdateProductView.as_view(), name='product-update'),

    # Categories
    path('categories/', ListCategoriesView.as_view(), name='category-list'),
]
```

### Migrations

```python
# ✅ Checks
class Migration(migrations.Migration):
    dependencies = [
        ('products', '0001_initial'),
    ]

    operations = [
        # 1. New fields have a default value or allow null
        migrations.AddField(
            model_name='product',
            name='stock',
            field=models.IntegerField(default=0),  # Default value provided
        ),

        # 2. Data migrations live in a separate migration
        # 3. Avoid dropping fields directly (deprecate first, then drop)
    ]
```

## Common Issues Quick Reference

### N+1 Queries

```python
# ❌ N+1
for product in Product.objects.all():
    print(product.category.name)  # Query on every iteration

# ✅ Optimized
for product in Product.objects.select_related('category'):
    print(product.category.name)  # Single query
```

### Bulk Operations

```python
# ❌ One-by-one create
for item in items:
    Product.objects.create(**item)

# ✅ Bulk create
Product.objects.bulk_create([Product(**item) for item in items])
```

### Security

```python
# ❌ SQL injection risk
Product.objects.raw(f"SELECT * FROM product WHERE name = '{name}'")

# ✅ Parameterized query
Product.objects.raw("SELECT * FROM product WHERE name = %s", [name])
Product.objects.filter(name=name)
```

### Type Annotations

```python
# ❌ Missing types
def get_product(id):
    return Product.objects.get(id=id)

# ✅ With type annotations
def get_product(id: int) -> Product:
    return Product.objects.get(id=id)
```
