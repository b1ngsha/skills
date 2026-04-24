# Python Conventions

## Rule Index

| Rule ID | Priority | Description                                           |
| ------- | -------- | ----------------------------------------------------- |
| py-001  | P2       | Functions must have type annotations                  |
| py-002  | P2       | Avoid the `Any` type                                  |
| py-003  | P2       | Handle `Optional` correctly                           |
| py-004  | P3       | Use Pydantic                                          |
| py-005  | P3       | Use Enum instead of magic strings                     |
| py-006  | P3       | Exception handling conventions                        |
| py-007  | P3       | Logging conventions                                   |
| py-008  | P3       | Use pathlib for path handling                         |
| py-009  | P2       | Avoid Django settings as default arguments            |
| py-010  | P3       | Avoid shadowing built-in functions/keywords           |
| py-011  | P3       | Avoid premature abstraction                           |

---

## py-001: Functions Must Have Type Annotations

**Priority**: P2

**Rule**: Every function (including methods) must have complete type annotations.

```python
# ❌ Incorrect — missing annotations
def get_user(user_id):
    return User.objects.get(id=user_id)

def calculate_total(items):
    return sum(item.price for item in items)

# ✅ Correct — fully annotated
from decimal import Decimal
from typing import Iterable

def get_user(user_id: int) -> User:
    return User.objects.get(id=user_id)

def calculate_total(items: Iterable[OrderItem]) -> Decimal:
    return sum(item.price for item in items)
```

---

## py-002: Avoid the `Any` Type

**Priority**: P2

**Rule**: Avoid `Any`; use concrete types or generics instead.

```python
from typing import Any, TypeVar, Generic

# ❌ Incorrect — using Any
def process_data(data: Any) -> Any:
    return data

# ✅ Correct — concrete type
def process_data(data: dict[str, str]) -> dict[str, str]:
    return data

# ✅ Correct — generic
T = TypeVar('T')

def first_item(items: list[T]) -> T | None:
    return items[0] if items else None
```

---

## py-003: Handle `Optional` Correctly

**Priority**: P2

**Rule**: When using `Optional`, always handle the `None` case.

```python
from typing import Optional

# ❌ Incorrect — None not handled
def get_username(user: Optional[User]) -> str:
    return user.username  # May raise AttributeError

# ✅ Correct — None handled
def get_username(user: Optional[User]) -> str:
    if user is None:
        return "Anonymous"
    return user.username

# ✅ Or Python 3.10+ syntax
def get_username(user: User | None) -> str:
    return user.username if user else "Anonymous"
```

---

## py-004: Use Pydantic

**Priority**: P3

**Rule**: Use Pydantic to define data structures.

```python
# ❌ Incorrect — plain dict
def create_response(code: int, message: str, data: dict) -> dict:
    return {
        "code": code,
        "message": message,
        "data": data
    }

# ✅ Correct — use Pydantic
from pydantic import BaseModel

class Response(BaseModel, Generic[T]):
    code: int
    message: str
    data: T
```

---

## py-005: Use Enum Instead of Magic Strings

**Priority**: P3

**Rule**: Use Enum for fixed option values.

```python
# ❌ Incorrect — magic strings
def update_order_status(order_id: int, status: str) -> None:
    if status not in ['pending', 'paid', 'shipped', 'completed']:
        raise ValueError("Invalid status")
    # ...

# ✅ Correct — use Enum
from enum import Enum

class OrderStatus(str, Enum):
    PENDING = 'pending'
    PAID = 'paid'
    SHIPPED = 'shipped'
    COMPLETED = 'completed'

def update_order_status(order_id: int, status: OrderStatus) -> None:
    # Type-safe with IDE autocomplete
    ...

# Usage in a Django Model
class Order(models.Model):
    status = models.CharField(
        max_length=20,
        choices=[(s.value, s.name) for s in OrderStatus],
        default=OrderStatus.PENDING.value
    )
```

### Layered Enum Usage

For HTTP Client and similar layered scenarios, Enum usage differs by layer:

| Layer                                  | Type        | Default                  | Purpose                           |
| -------------------------------------- | ----------- | ------------------------ | --------------------------------- |
| Public API (Client method parameters)  | `EnumClass` | `EnumClass.VALUE`        | Type safety + IDE autocomplete    |
| Internal data model (Pydantic Request) | `str`       | `EnumClass.VALUE.value`  | Serialization-friendly            |
| Boundary conversion                    | —           | `enum_param.value`       | Enum → str                        |

```python
# constants.py - Define Enum
import enum

class AmapExtensions(enum.Enum):
    """Controls whether district boundary coordinates are returned"""
    BASE = "base"
    ALL = "all"

# data_models.py - Pydantic model uses str + .value
from pydantic import BaseModel

class AmapDistrictRequest(BaseModel):
    """Amap district query request"""
    keywords: str
    extensions: str = AmapExtensions.BASE.value  # Use .value to extract the string

# client.py - Public API uses Enum type
class AmapDistrictClient:
    def get_district(
        self,
        *,
        keywords: str = "",
        extensions: AmapExtensions = AmapExtensions.BASE,  # Enum type
    ) -> AmapDistrictResponse:
        request_model = AmapDistrictRequest(
            keywords=keywords,
            extensions=extensions.value,  # Boundary conversion: Enum → str
        )
        # ...
```

---

## py-006: Exception Handling Conventions

**Priority**: P3

**Rule**: Follow exception handling best practices.

```python
# ❌ Incorrect — catch all exceptions
try:
    do_something()
except Exception:
    pass  # Swallow exception

# ❌ Incorrect — too broad
try:
    user = User.objects.get(id=user_id)
except Exception:
    return None

# ✅ Correct — catch specific exception
try:
    user = User.objects.get(id=user_id)
except User.DoesNotExist:
    raise UserNotFoundError(f"User {user_id} not found")

# ✅ Correct — custom exception
class BusinessError(Exception):
    """Base business exception"""
    def __init__(self, message: str, code: str = "BUSINESS_ERROR"):
        self.message = message
        self.code = code
        super().__init__(message)

class UserNotFoundError(BusinessError):
    def __init__(self, message: str):
        super().__init__(message, "USER_NOT_FOUND")
```

---

## py-007: Logging Conventions

**Priority**: P3

**Rule**: Use the standard logging module; avoid `print`.

```python
import logging

logger = logging.getLogger(__name__)

# ❌ Incorrect — using print
def process_order(order_id: int) -> None:
    print(f"Processing order {order_id}")

# ✅ Correct — using logging
def process_order(order_id: int) -> None:
    logger.info("Processing order", extra={"order_id": order_id})

    try:
        # business logic
        pass
    except PaymentError as e:
        logger.error(
            "Payment failed",
            extra={"order_id": order_id, "error": str(e)},
            exc_info=True  # Include stack trace
        )
        raise
```

---

## py-008: Use pathlib for Paths

**Priority**: P3

**Rule**: Prefer `pathlib` over `os.path`.

```python
# ❌ Incorrect — using os.path
import os

file_path = os.path.join(os.path.dirname(__file__), 'data', 'config.json')
if os.path.exists(file_path):
    with open(file_path) as f:
        data = json.load(f)

# ✅ Correct — using pathlib
from pathlib import Path

file_path = Path(__file__).parent / 'data' / 'config.json'
if file_path.exists():
    data = json.loads(file_path.read_text())
```

---

## py-009: Avoid Django Settings as Default Arguments

**Priority**: P2

**Rule**: Do not use values from `django.conf.settings` as default function/method arguments. Default arguments are evaluated at module import time, which causes:

1. `override_settings` in tests to be ignored (the imported value is captured)
2. `ImproperlyConfigured` if the module is imported before Django finishes configuration

```python
from django.conf import settings

# ❌ Incorrect — settings evaluated at import time
class ApiClient:
    def __init__(
        self,
        base_url=settings.API_BASE_URL,  # Captured at import; override_settings has no effect
        timeout=settings.API_TIMEOUT,
    ):
        self.base_url = base_url
        self.timeout = timeout

# ✅ Correct — use None as default and resolve in the body
class ApiClient:
    def __init__(
        self,
        base_url: str | None = None,
        timeout: int | None = None,
    ):
        self.base_url = base_url or settings.API_BASE_URL
        self.timeout = timeout if timeout is not None else settings.API_TIMEOUT

# ✅ Correct — sentinel value when falsy values are also valid
_UNSET = object()

class ApiClient:
    def __init__(
        self,
        timeout: int | object = _UNSET,
    ):
        self.timeout = settings.API_TIMEOUT if timeout is _UNSET else timeout
```

**Applies to**:

- HTTP Client `base_url`, `timeout`, etc.
- Any configurable parameter sourced from `settings`

**Exceptions**:

- If the parameter never needs to be overridden in tests AND the module is guaranteed to be imported after Django setup, this is acceptable (still recommended to follow the rule).

---

## py-010: Avoid Shadowing Built-in Functions/Keywords

**Priority**: P3

**Rule**: Variable, parameter, and field names must not shadow Python built-ins or keywords (e.g., `filter`, `type`, `id`, `list`, `dict`). Shadowing causes:

1. Hard-to-debug bugs from overridden built-ins
2. Reduced readability
3. Confusing IDE hints

When external APIs require these names, map them via Pydantic `serialization_alias`.

```python
from pydantic import BaseModel, Field

# ❌ Incorrect — shadows built-ins
class Request(BaseModel):
    filter: str | None = None  # Shadows built-in filter()
    type: str = "default"      # Shadows built-in type()
    id: int                    # Shadows built-in id()

# ✅ Correct — descriptive names + serialization_alias
class Request(BaseModel):
    adcode_filter: str | None = Field(default=None, serialization_alias="filter")
    resource_type: str = Field(default="default", serialization_alias="type")
    resource_id: int = Field(serialization_alias="id")

# Usage
request = Request(adcode_filter="110000", resource_type="user", resource_id=123)

# Use alias when serializing (for API requests)
params = request.model_dump(by_alias=True)
# Output: {"filter": "110000", "type": "user", "id": 123}

# Internal code uses semantic field names
print(request.adcode_filter)  # "110000"
```

**Common names to avoid**:

| Built-in | Suggested replacement                       |
| -------- | ------------------------------------------- |
| `filter` | `adcode_filter`, `name_filter`, `query`     |
| `type`   | `resource_type`, `item_type`, `kind`        |
| `id`     | `resource_id`, `item_id`, `pk`              |
| `list`   | `items`, `data_list`, `records`             |
| `dict`   | `data`, `mapping`, `config`                 |
| `input`  | `user_input`, `request_data`, `payload`     |
| `format` | `output_format`, `data_format`, `layout`    |

---

## py-011: Avoid Premature Abstraction

**Priority**: P3

**Rule**: Extract only when reuse appears. Applies to variable definition, constants, method extraction, etc. Do not create separate methods, constants, or utility functions for code used only once.

### When to Extract

| Situation                       | Action                                       |
| ------------------------------- | -------------------------------------------- |
| Used in only one place          | Keep inline; do not extract                  |
| Repeated in 2+ places           | Extract; placement depends on reuse scope    |
| Possibly reusable in the future | Defer; refactor when actual reuse occurs     |

### Extraction Scope

Decide placement by reuse scope:

| Reuse scope         | Placement                                                           |
| ------------------- | ------------------------------------------------------------------- |
| Within one method   | Local variable or inline                                            |
| Within one class    | Private method (`_method`)                                          |
| Within one file     | Module-level private function (`_function`) or top-of-file constant |
| Within one module   | Module's `utils.py` or `constants.py`                               |
| Across modules      | Common module (e.g., `makit/common/` or `makit/utils/`)             |

```python
# ❌ Incorrect — premature extraction; mapping used only once
class ImageService:
    def generate_upload_credential(self, content_type: str, ...):
        file_ext = Path(filename).suffix.lower() or self._get_ext_from_content_type(content_type)
        ...

    def _get_ext_from_content_type(self, content_type: str) -> str:
        """Get file extension from MIME type."""
        mapping = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
        }
        return mapping.get(content_type, ".jpg")


# ✅ Correct — keep inline since it is used in only one place
class ImageService:
    def generate_upload_credential(self, content_type: str, ...):
        ext_mapping = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
        }
        file_ext = Path(filename).suffix.lower() or ext_mapping.get(content_type, ".jpg")
        ...
```
