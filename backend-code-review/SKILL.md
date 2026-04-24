---
name: backend-code-review
description: Django + DRF + Python backend code review skill. Use for PR review, security audit, data integrity, type safety, Django/DRF best practices, and performance optimization. Trigger when user asks for "backend review", "Python review", "Django review", "API review", "PR review backend", or similar requests.
---

# Backend Code Review

> Django + DRF + Python code review skill

## Description

Use this skill when the user requests backend code review. Trigger phrases include: "backend review", "Python review", "Django review", "API review", "PR review backend".

## Tech Stack

- **Framework**: Django 5.1 + Django REST Framework
- **Language**: Python 3.12
- **Type Checking**: mypy + django-stubs
- **Linting**: ruff
- **Database**: MySQL (PyMySQL)
- **Cache**: Redis (django-redis)
- **Task Queue**: Celery

## Review Workflow

### 1. Fetch code changes

```bash
# Current branch vs develop
git diff develop...HEAD --name-only

# Or for a specific PR, get changed files from the PR URL
```

### 2. Categorized review

Review by file type:

| File Type                  | Review Focus                                       |
| -------------------------- | -------------------------------------------------- |
| `models.py`                | Data model design, field types, indexes            |
| `serializers.py`           | Serialization logic, validation rules, performance |
| `views.py` / `viewsets.py` | API logic, permissions, exception handling         |
| `urls.py`                  | Routing design, naming conventions                 |
| `migrations/`              | Migration safety, data migration                   |
| `tests.py`                 | Test coverage, test quality                        |

### 3. Output report

```markdown
## Code Review Report

### 📊 Overview

- Files changed: N
- Lines added: +XXX
- Lines removed: -XXX

### 🔴 Critical Issues (P0-P1)

Must fix; do not merge otherwise.

### 🟡 Suggested Improvements (P2-P3)

Recommended fixes that improve code quality.

### 🟢 Good Practices

Code worth highlighting.

### 💡 Improvement Suggestions

Optional optimization directions.
```

## Rule Priorities

| Priority | Category           | Prefix    | Description                              |
| -------- | ------------------ | --------- | ---------------------------------------- |
| P0       | Security           | `sec-*`   | SQL injection, XSS, auth bypass          |
| P1       | Data integrity     | `db-*`    | Data loss, missing constraints           |
| P2       | Type safety        | `py-*`    | Type errors, runtime exceptions          |
| P3       | Django conventions | `dj-*`    | Best practices, performance issues       |
| P4       | DRF conventions    | `drf-*`   | API design, serialization                |
| P5       | Code style         | `style-*` | Naming, formatting, comments             |

## Quick Checklist

### Security (P0)

- [ ] No raw SQL concatenation; use ORM or parameterized queries
- [ ] User input is validated and sanitized
- [ ] Sensitive data is not stored in plaintext
- [ ] APIs have appropriate permission controls
- [ ] No hardcoded keys/passwords

### Database (P1)

- [ ] Foreign keys have appropriate `on_delete` strategies
- [ ] Frequently queried fields have `db_index`
- [ ] No N+1 query issues
- [ ] Bulk operations use `bulk_create` / `bulk_update`
- [ ] Transaction boundaries are correct

### Type Safety (P2)

- [ ] Functions have type annotations
- [ ] No `Any` type abuse
- [ ] Optional types correctly handle `None`
- [ ] Generic types used correctly

### Django (P3)

- [ ] Models have `__str__` method
- [ ] Use `get_object_or_404` instead of try/except
- [ ] QuerySets use `select_related` / `prefetch_related`
- [ ] Configurations are separated (development/production)

### DRF (P4)

- [ ] Serializer fields are explicitly declared
- [ ] Use `@action` decorator for extra operations
- [ ] Pagination is configured
- [ ] Error response format is consistent

## Detailed Rules

See the `references/` directory for detailed rules:

- `rules/django-best-practices.md` - Django best practices
- `rules/drf-api-standards.md` - DRF API standards
- `rules/python-conventions.md` - Python conventions
- `rules/security-checks.md` - Security checks
- `rules/performance-db.md` - Database performance
- `rules/error-handling.md` - Exception handling

- `examples/good-patterns.md` - Recommended patterns
- `examples/bad-patterns.md` - Anti-patterns
