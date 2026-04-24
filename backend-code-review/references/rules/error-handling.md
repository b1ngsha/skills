# Exception Handling Rules

## Rule Index

| Rule ID | Priority | Description                       |
| ------- | -------- | --------------------------------- |
| err-001 | P2       | Do not catch all exceptions       |
| err-002 | P3       | Use custom business exceptions    |
| err-003 | P3       | Log exceptions properly           |
| err-004 | P3       | Unified DRF exception handling    |
| err-005 | P3       | Use `raise from`                  |
| err-006 | P3       | Use `finally` for resource cleanup |

---

## err-001: Do Not Catch All Exceptions

**Priority**: P2

**Rule**: Catch only expected exceptions; avoid hiding errors.

```python
# ❌ Dangerous — catches everything
try:
    do_something()
except Exception:
    pass  # Swallows all exceptions, including programming errors

# ❌ Dangerous — too broad
try:
    user = User.objects.get(id=user_id)
    process(user)
except Exception as e:
    logger.error(e)
    return None

# ✅ Correct — catch specific exceptions
try:
    user = User.objects.get(id=user_id)
except User.DoesNotExist:
    raise UserNotFoundError(f"User {user_id} not found")

try:
    result = external_api_call()
except requests.Timeout:
    raise ServiceUnavailableError("API timeout")
except requests.RequestException as e:
    raise ServiceUnavailableError(f"API error: {e}")
```

---

## err-002: Use Custom Business Exceptions

**Priority**: P3

**Rule**: Define a hierarchy of business exceptions.

```python
# common/exceptions.py

class BusinessError(Exception):
    """Base business exception"""
    code = "BUSINESS_ERROR"
    status_code = 400

    def __init__(self, message: str, code: str | None = None):
        self.message = message
        if code:
            self.code = code
        super().__init__(message)

class NotFoundError(BusinessError):
    """Resource not found"""
    code = "NOT_FOUND"
    status_code = 404

class PermissionDeniedError(BusinessError):
    """Permission denied"""
    code = "PERMISSION_DENIED"
    status_code = 403

class ValidationError(BusinessError):
    """Validation failed"""
    code = "VALIDATION_ERROR"
    status_code = 400

    def __init__(self, message: str, errors: dict | None = None):
        super().__init__(message)
        self.errors = errors or {}

class ConflictError(BusinessError):
    """Data conflict"""
    code = "CONFLICT"
    status_code = 409

# Usage example
def get_product(product_id: int) -> Product:
    try:
        return Product.objects.get(id=product_id)
    except Product.DoesNotExist:
        raise NotFoundError(f"Product {product_id} not found")

def create_order(user: User, product_id: int) -> Order:
    product = get_product(product_id)

    if product.stock < 1:
        raise ValidationError("Insufficient stock", errors={"stock": "Current stock is 0"})

    if Order.objects.filter(user=user, product=product, status='pending').exists():
        raise ConflictError("A pending order already exists")

    return Order.objects.create(user=user, product=product)
```

---

## err-003: Log Exceptions Properly

**Priority**: P3

**Rule**: Use the right log level and include necessary context.

```python
import logging

logger = logging.getLogger(__name__)

# ❌ Incorrect — insufficient information
try:
    process_order(order_id)
except Exception as e:
    logger.error(e)  # No stack trace, no context

# ✅ Correct — include context and stack trace
try:
    process_order(order_id)
except ValidationError as e:
    # Business exception — warning level
    logger.warning(
        "Order validation failed",
        extra={"order_id": order_id, "error": str(e)}
    )
    raise
except Exception as e:
    # Unexpected exception — error level + stack trace
    logger.error(
        "Unexpected error processing order",
        extra={"order_id": order_id},
        exc_info=True  # Includes stack trace
    )
    raise

# ✅ Log level guide
# DEBUG: debug info
# INFO: normal business events
# WARNING: recoverable exceptions, business warnings
# ERROR: errors that require attention
# CRITICAL: system-level failures
```

---

## err-004: Unified DRF Exception Handling

**Priority**: P3

**Rule**: Configure a single DRF exception handler.

```python
# common/handlers.py
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status

def custom_exception_handler(exc, context):
    # Call DRF default handler first
    response = exception_handler(exc, context)

    # Handle custom business exceptions
    if isinstance(exc, BusinessError):
        return Response(
            {
                "success": False,
                "error": {
                    "code": exc.code,
                    "message": exc.message,
                    "details": getattr(exc, 'errors', None)
                }
            },
            status=exc.status_code
        )

    # Handle DRF built-in exceptions
    if response is not None:
        return Response(
            {
                "success": False,
                "error": {
                    "code": response.status_code,
                    "message": get_error_message(response.data),
                    "details": response.data if isinstance(response.data, dict) else None
                }
            },
            status=response.status_code
        )

    # Unhandled exception
    return Response(
        {
            "success": False,
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "Internal server error"
            }
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR
    )

def get_error_message(data):
    """Extract a message from DRF error data"""
    if isinstance(data, dict):
        if 'detail' in data:
            return str(data['detail'])
        # Return the first error
        for key, value in data.items():
            if isinstance(value, list):
                return f"{key}: {value[0]}"
            return f"{key}: {value}"
    return str(data)

# settings.py
REST_FRAMEWORK = {
    'EXCEPTION_HANDLER': 'common.handlers.custom_exception_handler',
}
```

---

## err-005: Use `raise from`

**Priority**: P3

**Rule**: Use `raise from` to preserve the exception chain.

```python
# ❌ Loses original exception info
try:
    result = external_api.call()
except requests.RequestException as e:
    raise ServiceError("API call failed")  # Original exception lost

# ✅ Preserve the chain
try:
    result = external_api.call()
except requests.RequestException as e:
    raise ServiceError("API call failed") from e  # Preserves original

# ✅ Explicitly suppress the chain
try:
    result = external_api.call()
except requests.RequestException:
    raise ServiceError("API call failed") from None  # Explicitly drops the original
```

---

## err-006: Use `finally` for Resource Cleanup

**Priority**: P3

**Rule**: Use `finally` or context managers to ensure resources are released.

```python
# ❌ Resource leak risk
def process_file(path: str):
    f = open(path)
    data = f.read()  # If this raises, the file is never closed
    f.close()
    return process(data)

# ✅ Use finally
def process_file(path: str):
    f = open(path)
    try:
        data = f.read()
        return process(data)
    finally:
        f.close()

# ✅ Use context manager (preferred)
def process_file(path: str):
    with open(path) as f:
        data = f.read()
        return process(data)

# ✅ Database connection
from django.db import connection

def raw_query():
    with connection.cursor() as cursor:
        cursor.execute("SELECT ...")
        return cursor.fetchall()
    # cursor is closed automatically
```
