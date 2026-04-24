# Web & API Surface

Checks for HTTP/REST/GraphQL/gRPC endpoints. Run automated scanners first, then manual review for logic/authz gaps.

## Injection (any kind)

The general rule: **never build an interpreter input by string concatenation with untrusted data**. Use parameterized APIs.

| Injection type | Suspicious pattern | Safe alternative |
|---|---|---|
| SQL | `f"SELECT ... {x}"`, `.raw(...)`, `.extra(where=[...])`, `cursor.execute(s % x)` | ORM `.filter()`, parameterized `cursor.execute(s, params)` |
| NoSQL | `{"$where": req.body.q}`, regex from input without escape | Typed query operators, schema validation |
| OS command | `subprocess.run(s, shell=True)`, `os.system`, `exec`, backticks | `subprocess.run([...], shell=False)`, allowlist binaries |
| LDAP | `f"(uid={user})"` | LDAP escape: `ldap.filter.escape_filter_chars` |
| Template / SSTI | `render_template_string(user_input)`, Jinja from user input | Static templates only; render with context dict |
| XPath | `f"//user[name='{name}']"` | Parameterized XPath via library |
| Header / CRLF | `Location: ` + raw input containing `\r\n` | Strip CRLF, use framework redirect helpers |
| Log injection | Logging raw user input that includes newlines | Structured logging; escape newlines |

Detection:

```bash
# SQL/ORM raw paths (Python)
rg "\.raw\(|\.extra\(|cursor\.execute.*%[^,]" --type py
rg "f['\"].*SELECT |\".*\".*\+.*FROM " --type py

# Shell injection (any lang)
rg "shell=True|os\.system\(|subprocess\.\w+\([^,)]*\$|exec\(" 

# Template injection
rg "render_template_string|jinja2\.Template\(|new Function\("
```

## Cross-Site Scripting (XSS)

Three classes:

- **Reflected**: untrusted input echoed in same response without encoding.
- **Stored**: untrusted input persisted then rendered to other users.
- **DOM-based**: client-side JS reads from `location`, `document.referrer`, `postMessage` and writes to DOM via `innerHTML`/`outerHTML`/`document.write`.

Defenses (in order of preference):

1. Use a templating engine that auto-escapes (Django templates, JSX, Vue) and **never** disable it (`|safe`, `dangerouslySetInnerHTML`, `v-html`) for untrusted data.
2. Apply a strict Content Security Policy (`script-src 'self'`, no `'unsafe-inline'`, no `'unsafe-eval'`).
3. For rich-text input, sanitize with a vetted library (DOMPurify, bleach) — never roll your own regex sanitizer.

Detection:

```bash
rg "dangerouslySetInnerHTML|v-html|\|\s*safe\b|innerHTML\s*=|outerHTML\s*=|document\.write\("
```

## Server-Side Request Forgery (SSRF)

Triggered when the server fetches a URL provided by the user (image proxy, webhook, link preview, file import).

Risks: read cloud metadata (`http://169.254.169.254/`), pivot into internal network, scan localhost services, exfiltrate data via DNS.

Mitigations:

- Allowlist of permitted hosts/schemes; deny by default.
- Resolve DNS server-side, then validate the resolved IP is **not** in private/loopback/link-local ranges (RFC1918, 127/8, 169.254/16, IPv6 fc00::/7, ::1).
- Re-resolve on connect (defeat DNS rebinding) — or use a library that does this (e.g. `safeurl`).
- Disable redirects or validate each hop.
- Block egress to metadata endpoints at network layer for cloud workloads.

Detection:

```bash
rg "requests\.(get|post|put)\(\w+|urllib\.request\.urlopen\(\w+|fetch\(\w+\)|axios\.\w+\(\w+\)" 
```

For each hit, check whether the URL argument is user-controlled.

## Cross-Site Request Forgery (CSRF)

State-changing endpoints reachable via cookie auth need CSRF protection. Modern defaults:

- Use `SameSite=Lax` (or `Strict` for sensitive ops) on session cookies.
- Use CSRF tokens for non-idempotent requests when supporting older browsers or cross-origin POST.
- Prefer `Authorization: Bearer` tokens for APIs (not auto-sent by browsers; immune to CSRF).

Pitfalls:

- `SameSite=None` without `Secure` is rejected by browsers.
- GET endpoints performing state changes (e.g. `/logout`, `/transfer?amount=...`) — change to POST + CSRF.
- CORS misconfig (`Access-Control-Allow-Origin: *` with `Allow-Credentials: true`) — browsers block this, but reflective `Allow-Origin` from `Origin` header without an allowlist is the common bug.

## Insecure Direct Object Reference (IDOR)

The single most common real-world authz bug.

Pattern: endpoint takes an ID, fetches the object by ID, returns it — **without checking the requester owns it**.

```python
# VULNERABLE
def get_invoice(request, invoice_id):
    invoice = Invoice.objects.get(id=invoice_id)
    return JsonResponse(invoice.to_dict())

# CORRECT
def get_invoice(request, invoice_id):
    invoice = get_object_or_404(Invoice, id=invoice_id, owner=request.user)
    return JsonResponse(invoice.to_dict())
```

Detection: for every endpoint accepting an ID/slug/UUID, trace the data access. If `WHERE id = X` is not paired with `AND owner = current_user` (or equivalent permission check), it is suspect. UUIDs do **not** prevent IDOR — they reduce guessability, not authorization.

## Mass Assignment / Over-Posting

Endpoint deserializes the entire request body into a model. Attacker adds `{"is_admin": true, "balance": 1e9, "owner_id": <victim>}`.

Mitigations:

- Explicit serializer field allowlist (DRF: `fields = [...]`, never `__all__` for write).
- Read-only fields for server-controlled attributes (`id`, `created_at`, `owner`, `is_admin`).
- Use separate input/output schemas (Pydantic, Zod, JSON Schema).

Detection:

```bash
rg "fields\s*=\s*['\"]__all__|Meta:\s*$.*\n.*fields\s*=\s*'__all__'" --type py
```

## Open Redirect

`/login?next=...` or `/redirect?url=...` taking arbitrary URL.

Mitigations: allowlist of internal paths only, validate scheme + host before redirect, never trust input to determine the host part.

## Security Headers

Minimum modern set:

| Header | Recommended value |
|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` |
| `Content-Security-Policy` | strict per app; default `default-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'self'` |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | deny features not used (`camera=(), geolocation=()`...) |
| `Cache-Control` (auth pages, PII) | `no-store` |
| `X-Frame-Options` | `DENY` (or rely on `frame-ancestors` in CSP) |

Cookie flags: `Secure; HttpOnly; SameSite=Lax|Strict; Path=/; Max-Age=...`. JWT or session cookies without `HttpOnly` are XSS-stealable.

Quick check:

```bash
curl -sI https://target | rg -i "strict-transport|content-security|x-content-type|referrer-policy|set-cookie"
```

## CORS

Common bugs:

- `Access-Control-Allow-Origin: *` with credentialed requests (browser rejects, but reflective `Origin` works).
- `Access-Control-Allow-Origin: <reflected Origin>` with `Allow-Credentials: true` and no allowlist — any origin can read authenticated responses.
- `Access-Control-Allow-Methods: *` on internal API.

Correct pattern: allowlist of origins, no reflection, no `*` with credentials.

## Rate Limiting & Abuse Controls

Required on:

- Login (per-account + per-IP, slow on failure).
- Password reset / email verification (per-account + per-IP).
- Account creation (CAPTCHA + per-IP).
- Expensive endpoints (search, exports, AI calls).

Without these, expect: credential stuffing, account enumeration, resource exhaustion.

## GraphQL-Specific

- **Query depth & complexity limits**: enforce max depth (typical 10) and complexity score; without these, a single nested query DoSes the server.
- **Introspection in production**: disable if the API is not public.
- **Per-field authz**: GraphQL resolvers must each check authz; "I checked at the query root" misses nested field access.
- **Aliases & batching**: an attacker can request `id, id, id, ...` 100x to amplify; rate limit by complexity, not request count.

## gRPC-Specific

- **TLS always**: `grpc://` (insecure) only for localhost dev.
- **Auth interceptor**: enforce in a unary/stream interceptor, not per handler.
- **Reflection**: disable in production unless documented public API.
- **Message size limit**: lower than default (4MB) for endpoints not handling files.

## Verification Commands

```bash
# Headers & cookies
curl -sI -H "User-Agent: review" https://target | tee headers.txt

# CSRF / CORS probe (manual)
curl -i -H "Origin: https://evil.example" https://target/api/me

# Open redirect
curl -i "https://target/redirect?url=https://evil.example" | rg -i "^location"

# Common admin / debug surface
for p in /admin /actuator /debug /.env /.git/config /server-status; do
  curl -sI -o /dev/null -w "%{http_code} $p\n" "https://target$p"
done
```
