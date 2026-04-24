# Security Checks

## Rule Index

| Rule ID | Priority | Description                  |
| ------- | -------- | ---------------------------- |
| sec-001 | P0       | Prevent SQL injection        |
| sec-002 | P0       | Prevent XSS attacks          |
| sec-003 | P0       | Sensitive data protection    |
| sec-004 | P0       | Authentication & authorization |
| sec-005 | P1       | CSRF protection              |
| sec-006 | P1       | File upload safety           |
| sec-007 | P1       | Log redaction                |
| sec-008 | P0       | Dependency security          |

---

## sec-001: Prevent SQL Injection

**Priority**: P0 (Critical)

**Rule**: Never concatenate SQL strings; use the ORM or parameterized queries.

```python
# ❌ Critical vulnerability — SQL injection
def search_products(keyword: str):
    return Product.objects.raw(
        f"SELECT * FROM products WHERE name LIKE '%{keyword}%'"
    )

# ❌ Dangerous — using extra
Product.objects.extra(where=[f"name = '{name}'"])

# ✅ Correct — use the ORM
def search_products(keyword: str):
    return Product.objects.filter(name__icontains=keyword)

# ✅ Correct — parameterized raw query
def search_products(keyword: str):
    return Product.objects.raw(
        "SELECT * FROM products WHERE name LIKE %s",
        [f'%{keyword}%']
    )
```

---

## sec-002: Prevent XSS Attacks

**Priority**: P0 (Critical)

**Rule**: Validate and escape user input.

```python
# ❌ Dangerous — output user content directly
from django.utils.safestring import mark_safe

def render_comment(comment: str):
    return mark_safe(f"<div>{comment}</div>")  # XSS vulnerability

# ✅ Correct — Django templates auto-escape
# In template: {{ comment }}  # Auto-escaped

# ✅ Correct — manual escaping
from django.utils.html import escape

def render_comment(comment: str):
    return f"<div>{escape(comment)}</div>"

# ✅ Correct — DRF handles escaping by default
class CommentSerializer(serializers.ModelSerializer):
    # DRF escapes HTML by default
    class Meta:
        model = Comment
        fields = ['content']
```

---

## sec-003: Sensitive Data Protection

**Priority**: P0 (Critical)

**Rule**: Sensitive data must be encrypted at rest and never logged in plaintext.

```python
# ❌ Critical vulnerability — plaintext password
class User(models.Model):
    password = models.CharField(max_length=100)  # Stored in plaintext

# ❌ Dangerous — hardcoded secrets
SECRET_KEY = "my-super-secret-key"
API_KEY = "sk-1234567890"

# ✅ Correct — use Django password hashing
from django.contrib.auth.hashers import make_password, check_password

class User(models.Model):
    password_hash = models.CharField(max_length=128)

    def set_password(self, raw_password: str) -> None:
        self.password_hash = make_password(raw_password)

    def check_password(self, raw_password: str) -> bool:
        return check_password(raw_password, self.password_hash)

# ✅ Correct — use environment variables
import os
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')
API_KEY = os.environ.get('API_KEY')

# ✅ Correct — use django-environ
import environ
env = environ.Env()
SECRET_KEY = env('DJANGO_SECRET_KEY')
```

---

## sec-004: Authentication & Authorization

**Priority**: P0 (Critical)

**Rule**: Every API must have appropriate permission control.

```python
# ❌ Dangerous — no permission control
class ListProductsView(generics.ListAPIView):
    queryset = Product.objects.all()
    # Anyone can access

class CreateProductView(generics.CreateAPIView):
    # No permission_classes — anyone can create


# ❌ Dangerous — horizontal privilege escalation
class ListOrdersView(generics.ListAPIView):
    def get_queryset(self):
        return Order.objects.all()  # Sees everyone's orders


# ✅ Correct — different permissions per action
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny

class ListProductsView(generics.ListAPIView):
    """Public endpoint"""
    permission_classes = [AllowAny]
    serializer_class = ProductListSerializer

    def get_queryset(self):
        return Product.objects.filter(status='published')


class CreateProductView(generics.CreateAPIView):
    """Admin only"""
    permission_classes = [IsAdminUser]
    serializer_class = CreateProductSerializer


class UpdateProductView(generics.UpdateAPIView):
    """Authenticated + owner"""
    permission_classes = [IsAuthenticated, IsOwner]
    serializer_class = UpdateProductSerializer

    def get_queryset(self):
        return Product.objects.filter(seller=self.request.user)


# ✅ Correct — prevent horizontal privilege escalation
class ListOrdersView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderListSerializer

    def get_queryset(self):
        # Only the current user's orders
        return Order.objects.filter(user=self.request.user)


class RetrieveOrderView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = OrderDetailSerializer

    def get_queryset(self):
        # Only the user's own orders are accessible
        return Order.objects.filter(user=self.request.user)
```

---

## sec-005: CSRF Protection

**Priority**: P1

**Rule**: Ensure CSRF protection is configured correctly.

```python
# settings.py
MIDDLEWARE = [
    'django.middleware.csrf.CsrfViewMiddleware',  # Ensure enabled
    ...
]

# ❌ Dangerous — disable CSRF
@csrf_exempt
def my_view(request):
    ...

# ✅ Correct — DRF with Token/JWT auth disables CSRF safely
# DRF disables CSRF for token auth by default; this is safe

# ✅ Correct — disable only for specific endpoints (e.g., webhooks)
@csrf_exempt
@require_POST
def stripe_webhook(request):
    # Verify Stripe signature
    signature = request.headers.get('Stripe-Signature')
    verify_stripe_signature(request.body, signature)
    ...
```

---

## sec-006: File Upload Safety

**Priority**: P1

**Rule**: Validate file type and size to prevent malicious uploads.

```python
# ❌ Dangerous — no file validation
class ImageUploadView(APIView):
    def post(self, request):
        file = request.FILES['image']
        file.save(...)  # Could upload a malicious file

# ✅ Correct — validate file
from django.core.validators import FileExtensionValidator
from django.core.exceptions import ValidationError

ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'gif']
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB

class ImageUploadSerializer(serializers.Serializer):
    image = serializers.ImageField(
        validators=[FileExtensionValidator(ALLOWED_EXTENSIONS)]
    )

    def validate_image(self, value):
        if value.size > MAX_FILE_SIZE:
            raise ValidationError("File size must not exceed 5MB")

        # Check the real MIME type, not just the extension
        import magic
        mime = magic.from_buffer(value.read(1024), mime=True)
        value.seek(0)

        if mime not in ['image/jpeg', 'image/png', 'image/gif']:
            raise ValidationError("Unsupported file type")

        return value
```

---

## sec-007: Log Redaction

**Priority**: P1

**Rule**: Logs must not record sensitive information.

```python
import logging

logger = logging.getLogger(__name__)

# ❌ Dangerous — logs sensitive info
def login(request):
    logger.info(f"Login attempt: {request.data}")  # Includes password

# ✅ Correct — redact sensitive fields
def login(request):
    safe_data = {k: '***' if k in ['password', 'token'] else v
                 for k, v in request.data.items()}
    logger.info(f"Login attempt: {safe_data}")

# ✅ Correct — use a redaction helper
def mask_sensitive(data: dict, keys: list[str]) -> dict:
    return {k: '***' if k in keys else v for k, v in data.items()}

SENSITIVE_KEYS = ['password', 'token', 'secret', 'credit_card']
```

---

## sec-008: Dependency Security

**Priority**: P0

**Rule**: Audit and update dependencies regularly to fix known vulnerabilities.

```bash
# Use pip-audit
pip install pip-audit
pip-audit

# Use safety
pip install safety
safety check

# Add to CI
# .github/workflows/security.yml
- name: Security check
  run: |
    pip install pip-audit
    pip-audit --strict
```

```python
# pyproject.toml — pin major version, allow patches
dependencies = [
    "django>=5.1,<5.2",
    "djangorestframework>=3.15,<4.0",
]
```
