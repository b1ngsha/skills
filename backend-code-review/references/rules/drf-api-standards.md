# DRF API Standards

## Rule Index

| Rule ID | Priority | Description                                    |
| ------- | -------- | ---------------------------------------------- |
| drf-001 | P3       | Use `generics.XxxView`                         |
| drf-002 | P3       | View naming convention                         |
| drf-003 | P3       | Use `serializers.Serializer`                   |
| drf-004 | P4       | Separate input/output serializers              |
| drf-005 | P3       | Configure routes with `path` + View            |
| drf-006 | P3       | Optimize queries to avoid N+1                  |
| drf-007 | P3       | Configure pagination                           |
| drf-008 | P4       | Unified error response format                  |
| drf-009 | P4       | Use Throttling                                 |
| drf-010 | P3       | API versioning                                 |
| drf-011 | P2       | Place input validation in Serializers          |
| drf-012 | P2       | Use Permission Class for authorization checks  |

---

## drf-001: Use `generics.XxxView`

**Priority**: P3

**Rule**: Prefer `generics.XxxView` over `ViewSet`.

```python
# ❌ Incorrect — using ViewSet
class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer

# ✅ Correct — using generics.XxxView
class ProductListView(generics.ListAPIView):
    serializer_class = ProductListSerializer

    def get_queryset(self):
        return Product.objects.filter(status='published')


class ProductCreateView(generics.CreateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = CreateProductSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        product = ProductService.create_product(
            user=request.user,
            data=serializer.validated_data
        )

        return Response(
            ProductDetailSerializer(product).data,
            status=status.HTTP_201_CREATED
        )
```

| Scenario          | Recommended view class              |
| ----------------- | ----------------------------------- |
| List query        | `generics.ListAPIView`              |
| Detail query      | `generics.RetrieveAPIView`          |
| Create resource   | `generics.CreateAPIView`            |
| Update resource   | `generics.UpdateAPIView`            |
| Delete resource   | `generics.DestroyAPIView`           |
| Combined          | `generics.ListCreateAPIView`, etc.  |
| Custom action     | `APIView`                           |

---

## drf-002: View Naming Convention

**Priority**: P3

**Rule**: View name format is `{Entities}{Verb}View`. **View classes do NOT need a docstring**.

```python
# ❌ Incorrect — bad naming or unnecessary docstring
class ProductView(APIView): ...
class ProductsAPI(APIView): ...
class GetProducts(APIView): ...

class ProductListView(generics.ListAPIView):
    """Get product list"""  # ❌ View should not have docstring
    ...

# ✅ Correct — {Entities}{Verb}View, no docstring
class ProductListView(generics.ListAPIView):
    @extend_schema(
        description="Get product list",  # Use extend_schema for description
        ...
    )
    def get(self, request, *args, **kwargs):
        ...

class ProductRetrieveView(generics.RetrieveAPIView): ...
class ProductCreateView(generics.CreateAPIView): ...
class ProductUpdateView(generics.UpdateAPIView): ...
class ProductDeleteView(generics.DestroyAPIView): ...
class ProductPublishView(APIView): ...  # Custom action
class OrderCancelView(APIView): ...
```

---

## drf-003: Use `serializers.Serializer`

**Priority**: P3

**Rule**: For non-pure-CRUD scenarios, use `serializers.Serializer` instead of `ModelSerializer` to avoid coupling data manipulation with validation. **Serializer classes do NOT need a docstring**, and a field's `help_text` should be the **first** keyword argument.

```python
# ❌ Incorrect — using ModelSerializer for a complex scenario
class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = '__all__'

# ❌ Incorrect — Serializer has docstring; help_text in wrong position
class CreateOrderSerializer(serializers.Serializer):
    """Create order request"""  # ❌ docstring not needed
    address_id = serializers.IntegerField(min_value=1, help_text="Address ID")  # ❌ help_text should come first

# ✅ Correct — use Serializer; no docstring; help_text first
class CreateOrderSerializer(serializers.Serializer):
    address_id = serializers.IntegerField(help_text="Address ID", min_value=1)
    cart_items = CartItemSerializer(help_text="Cart items", many=True, min_length=1)
    coupon_code = serializers.CharField(help_text="Coupon code", required=False, allow_blank=True)

    def validate_address_id(self, value):
        user = self.context['request'].user
        if not UserAddress.objects.filter(id=value, user=user, is_deleted=False).exists():
            raise serializers.ValidationError("Shipping address does not exist")
        return value
```

| Scenario                          | Recommended approach            |
| --------------------------------- | ------------------------------- |
| Pure CRUD + no complex validation | `ModelSerializer` is acceptable |
| Complex validation logic          | `serializers.Serializer`        |
| Significant input/output diff     | Separate input/output serializers |
| Operations across multiple Models | `serializers.Serializer`        |

---

## drf-004: Separate Input/Output Serializers

**Priority**: P4

**Rule**: Use different serializers per scenario; define input and output separately.

```python


class ProductListSerializer(serializers.Serializer):
    """Product list response"""
    id = serializers.IntegerField()
    name = serializers.CharField()
    price = serializers.DecimalField(max_digits=10, decimal_places=2)
    thumbnail = serializers.URLField()
    category_name = serializers.CharField(source='category.name')


class ProductDetailSerializer(serializers.Serializer):
    """Product detail response"""
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField()
    price = serializers.DecimalField(max_digits=10, decimal_places=2)
    stock = serializers.IntegerField()
    category = CategoryDetailSerializer()
    seller = UserBriefSerializer()
    created_at = serializers.DateTimeField()


class CreateProductSerializer(serializers.Serializer):
    """Create product request"""
    name = serializers.CharField(max_length=100)
    description = serializers.CharField(max_length=2000, required=False, default='')
    price = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal('0.01'))
    category_id = serializers.IntegerField()
    stock = serializers.IntegerField(min_value=0)

    def validate_category_id(self, value):
        if not Category.objects.filter(id=value, is_active=True).exists():
            raise serializers.ValidationError("Category does not exist or is inactive")
        return value
```

| Purpose         | Naming format                  | Example                    |
| --------------- | ------------------------------ | -------------------------- |
| List output     | `{Entity}ListSerializer`       | `ProductListSerializer`    |
| Detail output   | `{Entity}DetailSerializer`     | `ProductDetailSerializer`  |
| Create input    | `Create{Entity}Serializer`     | `CreateProductSerializer`  |
| Update input    | `Update{Entity}Serializer`     | `UpdateProductSerializer`  |
| Generic input   | `{Action}{Entity}Serializer`   | `PublishProductSerializer` |

---

## drf-005: Configure Routes with `path` + View

**Priority**: P3

**Rule**: Use `path()` with standalone Views instead of `router.register()` + ViewSet.

```python
# ❌ Incorrect — router + ViewSet
router = DefaultRouter()
router.register('products', ProductViewSet, basename='product')
urlpatterns = [path('', include(router.urls))]

# ✅ Correct — path + View
from django.urls import path

urlpatterns = [
    # Products
    path('products/', ProductListView.as_view(), name='product-list'),
    path('products/<int:pk>/', ProductRetrieveView.as_view(), name='product-detail'),
    path('products/create/', ProductCreateView.as_view(), name='product-create'),
    path('products/<int:pk>/update/', ProductUpdateView.as_view(), name='product-update'),
    path('products/<int:pk>/delete/', ProductDeleteView.as_view(), name='product-delete'),

    # Custom action
    path('products/<int:pk>/publish/', PublishProductView.as_view(), name='product-publish'),

    # Categories
    path('categories/', CategoryListView.as_view(), name='category-list'),
]
```

| Action  | URL format                          | name format            |
| ------- | ----------------------------------- | ---------------------- |
| List    | `/{resources}/`                     | `{resource}-list`      |
| Detail  | `/{resources}/<int:pk>/`            | `{resource}-detail`    |
| Create  | `/{resources}/create/`              | `{resource}-create`    |
| Update  | `/{resources}/<int:pk>/update/`     | `{resource}-update`    |
| Delete  | `/{resources}/<int:pk>/delete/`     | `{resource}-delete`    |
| Custom  | `/{resources}/<int:pk>/{action}/`   | `{resource}-{action}`  |

---

## drf-006: Optimize Queries to Avoid N+1

**Priority**: P3

**Rule**: Use `select_related` and `prefetch_related` in `get_queryset` to optimize lookups.

```python
class ProductListView(generics.ListAPIView):
    serializer_class = ProductListSerializer

    def get_queryset(self):
        # List: join category
        return Product.objects.select_related('category').filter(is_active=True)


class ProductRetrieveView(generics.RetrieveAPIView):
    serializer_class = ProductDetailSerializer

    def get_queryset(self):
        # Detail: join more relations
        return Product.objects.select_related(
            'category', 'seller'
        ).prefetch_related(
            'images', 'tags'
        )
```

---

## drf-007: Configure Pagination

**Priority**: P3

**Rule**: List endpoints must be paginated to avoid returning excessive data.

```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}

# Custom pagination class
from rest_framework.pagination import PageNumberPagination

class StandardPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

# Usage in a View
class ProductListView(generics.ListAPIView):
    pagination_class = StandardPagination
```

---

## drf-008: Unified Error Response Format

**Priority**: P4

**Rule**: Use a unified error response format.

```python
# common/handlers.py
from rest_framework.views import exception_handler
from rest_framework.response import Response

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is not None:
        # Unified format
        response.data = {
            'success': False,
            'error': {
                'code': response.status_code,
                'message': get_error_message(response.data),
                'details': response.data if isinstance(response.data, dict) else None,
            }
        }

    return response

# settings.py
REST_FRAMEWORK = {
    'EXCEPTION_HANDLER': 'common.handlers.custom_exception_handler',
}
```

```json
// Error response example
{
  "success": false,
  "error": {
    "code": 400,
    "message": "Invalid request parameters",
    "details": {
      "price": ["Price must not be negative"]
    }
  }
}
```

---

## drf-009: Use Throttling

**Priority**: P4

**Rule**: Configure rate limiting for APIs.

```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour'
    }
}

# Per-view throttle
from rest_framework.throttling import UserRateThrottle

class BurstRateThrottle(UserRateThrottle):
    rate = '60/min'

class OrderCreateView(generics.CreateAPIView):
    throttle_classes = [BurstRateThrottle]
```

---

## drf-010: API Versioning

**Priority**: P3

**Rule**: Version APIs via URL or Header.

```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_VERSIONING_CLASS': 'rest_framework.versioning.URLPathVersioning',
    'DEFAULT_VERSION': 'v1',
    'ALLOWED_VERSIONS': ['v1', 'v2'],
}

# urls.py
urlpatterns = [
    path('api/<version>/', include('api.urls')),
]

# Access version inside the view
class ProductListView(generics.ListAPIView):
    def get_serializer_class(self):
        if self.request.version == 'v2':
            return ProductV2ListSerializer
        return ProductListSerializer
```

---

## drf-011: Place Input Validation in Serializers

**Priority**: P2

**Rule**: All input parameter validation should live in Serializers, not in Views or business logic (Service/Biz). Benefits:

- Single validation entry point — easier to maintain
- Leverages DRF validation, returning standard error format automatically
- Keeps the business layer pure

```python
# ❌ Incorrect — input validation in business layer
# biz/images.py
class ImageService:
    def generate_upload_credential(self, content_type: str, ...):
        if content_type not in settings.IMAGE_ALLOWED_TYPES:
            raise exceptions.ValidationError(
                {"content_type": f"Unsupported image type: {content_type}"}
            )
        ...

# ✅ Correct — input validation in Serializer
# apis/images/serializers.py
class UploadCredentialCreateInputSerializer(serializers.Serializer):
    content_type = serializers.ChoiceField(
        help_text="MIME type",
        choices=[(t, t) for t in settings.IMAGE_ALLOWED_TYPES],
    )
    ...

# biz/images.py — business layer no longer validates inputs
class ImageService:
    def generate_upload_credential(self, content_type: str, ...):
        # Use the already-validated parameters directly
        ...
```

| Validation type        | Location                       | Example                                    |
| ---------------------- | ------------------------------ | ------------------------------------------ |
| Format/type validation | Serializer field               | `ChoiceField`, `IntegerField(min_value=1)` |
| Resource existence     | Serializer `validate_*` method | Check that the image exists / has correct status |
| Business rules         | Serializer `validate_*` method | Check that the address belongs to the user |
| Cross-field            | Serializer `validate` method   | Start time must be earlier than end time   |
| Permissions            | Permission Class               | Whether the user may operate on this resource |

```python
# ✅ Resource existence and status validation in the Serializer
class ImageConfirmInputSerializer(serializers.Serializer):
    image_id = serializers.IntegerField(help_text="Image ID")

    def validate_image_id(self, value: int) -> int:
        try:
            image = Image.objects.get(id=value)
        except Image.DoesNotExist:
            raise serializers.ValidationError("Image not found")

        if image.status != ImageStatus.PENDING:
            raise serializers.ValidationError(f"Image status is invalid: {image.status}")

        # Stash the image object on context for downstream use
        self.context["image"] = image
        return value
```

---

## drf-012: Use Permission Class for Authorization Checks

**Priority**: P2

**Rule**: Resource-level permission checks should use DRF's Permission Class instead of manual checks in the business layer. Benefits:

- Single permission entry point
- Automatic 403 status code
- Reusable permission logic

```python
# ❌ Incorrect — permission check in the business layer
# biz/images.py
class ImageService:
    def confirm_upload(self, image_id: int, user_id: UUID) -> ImageInfo:
        image = Image.objects.get(id=image_id)
        if image.user_id != user_id:
            raise exceptions.PermissionDenied("Not allowed to operate on this image")
        ...

# ✅ Correct — use a Permission Class
# apis/images/permissions.py
class IsImageOwner(BasePermission):
    message = "Not allowed to operate on this image"

    def has_object_permission(self, request, view, obj: Image) -> bool:
        return obj.user_id == request.user.id

# apis/images/views.py
class ImageConfirmView(generics.CreateAPIView):
    permission_classes = [IsImageOwner]

    def post(self, request, *args, **kwargs):
        slz = ImageConfirmInputSerializer(data={"image_id": kwargs["pk"]})
        slz.is_valid(raise_exception=True)

        image = slz.context["image"]
        self.check_object_permissions(request, image)  # Run permission check

        return Response(ImageService().confirm_upload(image=image))

# biz/images.py — business layer focuses on logic only, no permission checks
class ImageService:
    def confirm_upload(self, image: Image) -> ImageInfo:
        # Use the already-authorized image object
        ...
```
