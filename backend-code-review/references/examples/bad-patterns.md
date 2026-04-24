# Backend Code Anti-Patterns

## 1. Model Anti-Patterns

```python
# ❌ Anti-pattern

class Product(models.Model):
    # Issue 1: Missing verbose_name
    name = models.CharField(max_length=100)

    # Issue 2: CharField uses null=True
    description = models.CharField(max_length=500, null=True, blank=True)

    # Issue 3: Magic string
    status = models.CharField(max_length=20, default='draft')

    # Issue 4: Foreign key missing related_name; on_delete intent unclear
    category = models.ForeignKey(Category, on_delete=models.CASCADE)

    # Issue 5: No index
    created_at = models.DateTimeField(auto_now_add=True)

    # Issue 6: Missing Meta class

    # Issue 7: Missing __str__ method

    # Issue 8: Business logic written directly in Model methods (should live in Service layer)
    def buy(self, user, quantity):
        if self.stock < quantity:
            return False
        self.stock -= quantity
        self.save()
        Order.objects.create(user=user, product=self, quantity=quantity)
        # Send email...
        # Write log...
        return True
```

**Notes**:
- Missing field labels — Admin display is unfriendly
- CharField should use empty string instead of NULL
- Magic strings should be replaced with TextChoices
- Foreign key configuration is incomplete
- Frequently queried fields lack indexes
- Complex business logic is coupled to the Model

---

## 2. Serializer Anti-Patterns

```python
# ❌ Anti-pattern

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = '__all__'  # Issue 1: exposes all fields

    # Issue 2: Missing validation logic

    # Issue 3: create/update method too complex
    def create(self, validated_data):
        user = self.context['request'].user
        # 50 lines of business logic...
        product = Product.objects.create(**validated_data)
        # Another 50 lines of business logic...
        return product


class OrderSerializer(serializers.ModelSerializer):
    # Issue 4: N+1 queries
    product_name = serializers.SerializerMethodField()
    user_name = serializers.SerializerMethodField()

    def get_product_name(self, obj):
        return obj.product.name  # Query per record

    def get_user_name(self, obj):
        return obj.user.username  # Another query per record
```

**Notes**:
- `__all__` may expose sensitive fields
- Complex logic belongs in the Service layer
- Nested lookups cause N+1

---

## 3. ViewSet Anti-Patterns

```python
# ❌ Anti-pattern

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()  # Issue 1: query not optimized
    serializer_class = ProductSerializer  # Issue 2: same serializer for all actions
    # Issue 3: no permission control

    def create(self, request):
        # Issue 4: manual handling, no Serializer
        name = request.data.get('name')
        price = request.data.get('price')

        # Issue 5: no validation
        product = Product.objects.create(name=name, price=price)

        return Response({'id': product.id})

    def list(self, request):
        # Issue 6: no pagination
        products = Product.objects.all()
        return Response(ProductSerializer(products, many=True).data)

    # Issue 7: oversized method
    @action(detail=True, methods=['post'])
    def purchase(self, request, pk=None):
        product = Product.objects.get(pk=pk)  # Issue 8: not using get_object

        # 100+ lines of business logic dumped here...
        user = request.user
        quantity = request.data.get('quantity', 1)

        if product.stock < quantity:
            return Response({'error': 'Insufficient stock'}, status=400)

        product.stock -= quantity
        product.save()

        order = Order.objects.create(
            user=user,
            product=product,
            quantity=quantity,
            amount=product.price * quantity
        )

        # Send email
        # Write log
        # Push notification
        # ...

        return Response({'order_id': order.id})
```

**Notes**:
- Queries not optimized (N+1)
- One serializer for all scenarios
- Missing permission control
- Manual data handling instead of using Serializer
- No pagination
- Business logic stuffed inside the View

---

## 4. Security Anti-Patterns

```python
# ❌ Anti-pattern

# Issue 1: SQL injection
def search(request):
    keyword = request.GET.get('q')
    products = Product.objects.raw(
        f"SELECT * FROM products WHERE name LIKE '%{keyword}%'"
    )
    return render(request, 'search.html', {'products': products})

# Issue 2: Horizontal privilege escalation
class OrderViewSet(viewsets.ModelViewSet):
    def get_queryset(self):
        return Order.objects.all()  # Sees everyone's orders

    def retrieve(self, request, pk=None):
        order = Order.objects.get(pk=pk)  # Can fetch any order
        return Response(OrderSerializer(order).data)

# Issue 3: Sensitive information leakage
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = '__all__'  # Includes password_hash

# Issue 4: Hardcoded secrets
SECRET_KEY = 'my-super-secret-key-123'
API_KEY = 'sk-1234567890abcdef'

# Issue 5: Logging sensitive data
def login(request):
    logger.info(f"Login: {request.data}")  # Includes password
```

---

## 5. Performance Anti-Patterns

```python
# ❌ Anti-pattern

# Issue 1: N+1 queries
def get_orders():
    orders = Order.objects.all()
    for order in orders:
        print(order.user.username)     # N queries
        print(order.product.name)      # Another N queries
        print(order.product.category.name)  # Yet another N queries

# Issue 2: Querying inside a loop
def process_items(item_ids):
    for item_id in item_ids:
        item = Item.objects.get(id=item_id)  # N queries
        process(item)

# Issue 3: Creating inside a loop
def create_items(data_list):
    for data in data_list:
        Item.objects.create(**data)  # N INSERTs

# Issue 4: count vs exists
def has_orders(user):
    return Order.objects.filter(user=user).count() > 0  # Scans all rows

# Issue 5: Loading unneeded fields
def get_product_names():
    products = Product.objects.all()  # Loads all fields
    return [p.name for p in products]

# Issue 6: No cache
def get_categories():
    return list(Category.objects.all())  # Hits DB every call

# Issue 7: Race condition
def increment_view(product_id):
    product = Product.objects.get(id=product_id)
    product.view_count = product.view_count + 1  # Race condition
    product.save()
```

---

## 6. Exception Handling Anti-Patterns

```python
# ❌ Anti-pattern

# Issue 1: Swallowing exceptions
def process():
    try:
        do_something()
    except Exception:
        pass  # Do nothing

# Issue 2: Catching too broadly
def get_user(user_id):
    try:
        return User.objects.get(id=user_id)
    except Exception:  # Includes programming errors
        return None

# Issue 3: Returning None instead of raising
def find_product(product_id):
    try:
        return Product.objects.get(id=product_id)
    except Product.DoesNotExist:
        return None  # Caller can't tell "not found" from "error"

# Issue 4: Losing exception chain
def call_api():
    try:
        response = requests.get(url)
        return response.json()
    except requests.RequestException:
        raise APIError("Request failed")  # Original exception lost

# Issue 5: Wrong log level
def process_order(order_id):
    try:
        do_process(order_id)
    except ValidationError as e:
        logger.error(f"Error: {e}")  # Business errors should not be 'error'
```
