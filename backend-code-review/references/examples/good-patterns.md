# Backend Code Good Patterns

## 1. Complete Model Definition

```python
from django.db import models
from django.utils import timezone
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .category import Category

class Product(models.Model):
    """Product model"""

    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        PUBLISHED = 'published', 'Published'
        ARCHIVED = 'archived', 'Archived'

    # Basic fields
    name = models.CharField('Name', max_length=100)
    description = models.TextField('Description', blank=True, default='')
    price = models.DecimalField('Price', max_digits=10, decimal_places=2)
    stock = models.PositiveIntegerField('Stock', default=0)

    # Relations
    category = models.ForeignKey(
        'Category',
        on_delete=models.PROTECT,
        related_name='products',
        verbose_name='Category'
    )

    # Status
    status = models.CharField(
        'Status',
        max_length=20,
        choices=Status.choices,
        default=Status.DRAFT,
        db_index=True
    )

    # Timestamps
    created_at = models.DateTimeField('Created at', auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField('Updated at', auto_now=True)

    class Meta:
        verbose_name = 'Product'
        verbose_name_plural = 'Products'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['category', 'status']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(price__gte=0),
                name='product_price_positive'
            ),
        ]

    def __str__(self) -> str:
        return self.name

    def publish(self) -> None:
        """Publish the product"""
        self.status = self.Status.PUBLISHED
        self.save(update_fields=['status', 'updated_at'])

    @property
    def is_available(self) -> bool:
        """Whether the product is available for purchase"""
        return self.status == self.Status.PUBLISHED and self.stock > 0
```

## 2. Complete Serializer Definition

```python
from rest_framework import serializers
from decimal import Decimal

class ProductListSerializer(serializers.ModelSerializer):
    """Product list serializer"""
    category_name = serializers.CharField(source='category.name', read_only=True)

    class Meta:
        model = Product
        fields = ['id', 'name', 'price', 'thumbnail', 'category_name', 'status']


class ProductDetailSerializer(serializers.ModelSerializer):
    """Product detail serializer"""
    category = CategorySerializer(read_only=True)
    seller = SellerSerializer(read_only=True)
    is_available = serializers.BooleanField(read_only=True)

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 'stock',
            'category', 'seller', 'status', 'is_available',
            'images', 'created_at'
        ]


class ProductCreateSerializer(serializers.ModelSerializer):
    """Product create serializer"""

    class Meta:
        model = Product
        fields = ['name', 'description', 'price', 'stock', 'category']

    def validate_price(self, value: Decimal) -> Decimal:
        if value <= 0:
            raise serializers.ValidationError("Price must be greater than 0")
        return value

    def validate(self, attrs: dict) -> dict:
        # Cross-field validation
        if attrs.get('stock', 0) > 0 and not attrs.get('price'):
            raise serializers.ValidationError({
                'price': 'Price is required when stock is positive'
            })
        return attrs

    def create(self, validated_data: dict) -> Product:
        # Auto-assign seller
        validated_data['seller'] = self.context['request'].user
        return super().create(validated_data)
```

## 3. Complete ViewSet Definition

```python
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django_filters.rest_framework import DjangoFilterBackend

class ProductViewSet(viewsets.ModelViewSet):
    """Product viewset"""

    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['category', 'status']
    search_fields = ['name', 'description']
    ordering_fields = ['price', 'created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        queryset = Product.objects.all()

        if self.action == 'list':
            queryset = queryset.select_related('category')
            queryset = queryset.only('id', 'name', 'price', 'thumbnail',
                                     'status', 'category__name')
        elif self.action == 'retrieve':
            queryset = queryset.select_related('category', 'seller')
            queryset = queryset.prefetch_related('images')

        # Non-admins only see published products
        if not self.request.user.is_staff:
            queryset = queryset.filter(status=Product.Status.PUBLISHED)

        return queryset

    def get_serializer_class(self):
        if self.action == 'list':
            return ProductListSerializer
        if self.action == 'retrieve':
            return ProductDetailSerializer
        if self.action in ['create', 'update', 'partial_update']:
            return ProductCreateSerializer
        return ProductDetailSerializer

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAuthenticated()]
        return []

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def publish(self, request, pk=None):
        """Publish a product"""
        product = self.get_object()

        if product.seller != request.user:
            return Response(
                {'detail': 'You can only publish your own products'},
                status=status.HTTP_403_FORBIDDEN
            )

        product.publish()
        return Response({'status': 'published'})

    @action(detail=False, methods=['get'])
    def featured(self, request):
        """Get featured products"""
        queryset = self.get_queryset().filter(is_featured=True)[:10]
        serializer = ProductListSerializer(queryset, many=True)
        return Response(serializer.data)
```

## 4. Service Layer

```python
# biz/products.py
from dataclasses import dataclass
from decimal import Decimal
from typing import Optional

from django.db import transaction

from makit.apps.products.models import Product
from makit.apps.orders.models import Order
from makit.common.exceptions import ValidationError, NotFoundError

@dataclass
class CreateProductInput:
    name: str
    price: Decimal
    category_id: int
    description: str = ''
    stock: int = 0

class ProductService:
    """Product business service"""

    @staticmethod
    def get_product(product_id: int) -> Product:
        """Get a product"""
        try:
            return Product.objects.select_related('category').get(id=product_id)
        except Product.DoesNotExist:
            raise NotFoundError(f"Product {product_id} not found")

    @staticmethod
    @transaction.atomic
    def create_product(user, input_data: CreateProductInput) -> Product:
        """Create a product"""
        # Validate category
        if not Category.objects.filter(id=input_data.category_id).exists():
            raise ValidationError("Category does not exist")

        product = Product.objects.create(
            name=input_data.name,
            price=input_data.price,
            category_id=input_data.category_id,
            description=input_data.description,
            stock=input_data.stock,
            seller=user,
        )

        return product

    @staticmethod
    @transaction.atomic
    def purchase_product(user, product_id: int, quantity: int = 1) -> Order:
        """Purchase a product"""
        # Lock the product row
        product = Product.objects.select_for_update().get(id=product_id)

        if product.stock < quantity:
            raise ValidationError("Insufficient stock")

        if product.status != Product.Status.PUBLISHED:
            raise ValidationError("Product is not available for purchase")

        # Decrement stock
        product.stock -= quantity
        product.save(update_fields=['stock'])

        # Create order
        order = Order.objects.create(
            user=user,
            product=product,
            quantity=quantity,
            amount=product.price * quantity,
        )

        return order
```

## 5. Test Cases

```python
import pytest
from decimal import Decimal
from django.urls import reverse
from rest_framework import status

from makit.apps.products.models import Product

@pytest.mark.django_db
class TestProductAPI:
    """Product API tests"""

    @pytest.fixture
    def product(self, category, user):
        return Product.objects.create(
            name='Test Product',
            price=Decimal('99.99'),
            category=category,
            seller=user,
            status=Product.Status.PUBLISHED,
            stock=10,
        )

    def test_list_products(self, api_client, product):
        """Test product list"""
        url = reverse('product-list')
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data['results']) == 1
        assert response.data['results'][0]['name'] == 'Test Product'

    def test_create_product_unauthenticated(self, api_client):
        """Unauthenticated users cannot create products"""
        url = reverse('product-list')
        response = api_client.post(url, {'name': 'New'})

        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_create_product(self, authenticated_client, category):
        """Create a product"""
        url = reverse('product-list')
        data = {
            'name': 'New Product',
            'price': '199.99',
            'category': category.id,
        }
        response = authenticated_client.post(url, data)

        assert response.status_code == status.HTTP_201_CREATED
        assert Product.objects.filter(name='New Product').exists()

    def test_publish_product(self, authenticated_client, product):
        """Publish a product"""
        product.status = Product.Status.DRAFT
        product.save()

        url = reverse('product-publish', args=[product.id])
        response = authenticated_client.post(url)

        assert response.status_code == status.HTTP_200_OK
        product.refresh_from_db()
        assert product.status == Product.Status.PUBLISHED
```
