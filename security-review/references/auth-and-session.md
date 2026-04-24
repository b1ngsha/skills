# Authentication, Session, Tokens

Most breaches go through the auth layer. This is where to spend manual-review time.

## Password Storage

| Algorithm | Verdict |
|---|---|
| Argon2id (memory >= 64MB, t >= 3, p = 1) | Preferred |
| bcrypt (cost >= 12) | Acceptable |
| scrypt (N >= 2^15, r=8, p=1) | Acceptable |
| PBKDF2-SHA256 (>= 600k iterations, OWASP 2023) | Acceptable |
| SHA-256/512 plain or salted | Broken — offline cracking trivial |
| MD5 / SHA-1 | Broken — also collision-vulnerable |
| Custom hash | Broken until proven otherwise |

Detection:

```bash
rg "hashlib\.(md5|sha1|sha256)|MessageDigest\.getInstance\(['\"](MD5|SHA-1)" 
rg "make_password|check_password" --type py    # Django: check the hashers configured
```

## Authentication Logic

- **Constant-time comparison** for secrets (`secrets.compare_digest`, `crypto.timingSafeEqual`). `==` on tokens leaks length and prefix via timing.
- **Generic error messages**: "Invalid email or password" — never "User not found" vs "Wrong password" (account enumeration).
- **Account lockout / progressive delay** after N failed attempts per account, per IP. Hard lockouts enable DoS; prefer exponential backoff + CAPTCHA.
- **Login audit log**: record success and failure with IP + UA + timestamp + user.
- **No "remember me" cookies that bypass MFA**.

## Session Management

- **Session ID generation**: cryptographically random (>= 128 bits entropy), framework default is usually correct; never use sequential or `time()`-based IDs.
- **Session fixation**: rotate session ID on login (`request.session.cycle_key()` in Django; `req.session.regenerate()` in Express).
- **Logout invalidates server-side**, not just clears cookie. Check that the session row is deleted or marked revoked.
- **Idle timeout** (15-30min for sensitive apps) and **absolute timeout** (8-12h).
- **Concurrent session limit** for high-value accounts.

Cookie flags (already in `web-and-api.md`):

```
Set-Cookie: session=<id>; Secure; HttpOnly; SameSite=Lax; Path=/; Max-Age=...
```

## JWT — Common Pitfalls

JWT misuse is a frequent finding source. Check each:

- **`alg: none` accepted** — devastating. Library must reject `alg: none` and any algorithm not in an explicit allowlist.
- **HS/RS confusion**: server validates with `verify(token, public_key)` accepting both `HS256` (which uses the public key as HMAC secret) and `RS256`. Allowlist exact algorithm.
- **Signature not verified**: `jwt.decode(token, ..., verify=False)` or `jwt.decode(token)` without secret — fatal.
- **No `exp` check** or excessive lifetime (> 1h for access tokens; refresh tokens separately).
- **No `aud` / `iss` check** on multi-service deployments — token issued for service A accepted by service B.
- **Secret in client code or repo** — search for `JWT_SECRET=`, `client_secret`, etc. in JS/RN bundles.
- **`kid` header injection**: `kid` used to load key without sanitization → path traversal or SQL injection via key lookup.
- **Long-lived tokens with no revocation** — JWTs are by design hard to revoke. For sensitive apps, use short access tokens + revocable refresh tokens; or maintain a deny-list keyed by `jti`.
- **Storing JWT in `localStorage`** — XSS-stealable. Prefer `HttpOnly` cookie + CSRF protection, or in-memory + silent refresh.

Detection:

```bash
rg "verify\s*=\s*False|algorithms\s*=\s*\[\s*['\"]none|jwt\.decode\([^,]+\)" 
rg "JWT_SECRET|jwt_secret|HS256.*secret"
```

## OAuth 2.0 / OIDC

- **PKCE for all public clients** (mobile, SPA). Without PKCE, authorization code interception is exploitable.
- **State parameter** required and verified on callback (CSRF on the OAuth flow).
- **Nonce** required and verified for OIDC implicit/hybrid flows.
- **Redirect URI exact match** at the authorization server. Any wildcard or subdirectory match is dangerous.
- **Avoid the implicit flow** (`response_type=token`). Use authorization code + PKCE.
- **Avoid the resource-owner password grant** entirely.
- **Token in URL fragment**: ends up in browser history, referrer headers, server logs. Use POST callback or fragment-only flows carefully.
- **Scope minimization**: request only what is needed; review what scopes the app actually accesses.
- **Refresh token rotation**: each use issues a new refresh token; reuse of an old one indicates compromise → revoke the chain.

## Multi-Factor Authentication

- **Required for**: admin accounts, accounts with destructive permissions, password reset confirmation, sensitive actions (transfer, delete account, change email).
- **TOTP** preferred over SMS (SIM-swap risk). WebAuthn / passkeys preferred over TOTP.
- **Backup codes**: high-entropy, single-use, hashed at rest.
- **Rate limit MFA verification** — same brute-force protection as login.
- **MFA bypass paths**: "remember this device" cookies, password-reset-then-login, OAuth login from MFA-disabled provider, support-portal account takeover. Audit each.

## Account Recovery

The weakest link. Common bugs:

- **Reset token guessable** (sequential, short, predictable).
- **Reset token long-lived** (> 1h is risky; > 24h is bad).
- **Reset token reusable** (must be one-time and invalidated on use).
- **No re-authentication** before changing email/password while logged in.
- **Email change without confirmation to old email** — enables account hijack via single-step compromise.
- **Security questions** as MFA — broken; remove or treat as info field only.
- **Magic link** sent to attacker-controllable address (open registration with email confirmation race).

## Authorization Checks

Authentication says "who are you". Authorization says "what may you do". The mistake is conflating them.

- **Object-level authz**: every read/write of a user-owned object verifies the caller owns it (or has explicit grant). See IDOR in `web-and-api.md`.
- **Function-level authz**: admin endpoints check role; do not rely on "the admin UI doesn't link to it" — endpoint URLs are guessable.
- **Default deny**: new endpoint without explicit permission decorator should fail closed. Verify framework default; many default open.
- **Privilege parameters from client**: never accept `role`, `is_admin`, `tenant_id`, `org_id` from request body or query string. Derive from the authenticated session.
- **Tenant isolation** (multi-tenant): every query joined to or filtered by `tenant_id`. Audit any query missing the filter.
- **Indirect privilege escalation**: low-priv user can edit a field whose value is consumed by a high-priv process (e.g. user sets `webhook_url`, admin worker fetches it → SSRF as worker).

## API Keys & Service Accounts

- **Per-client keys**, not shared.
- **Scoped permissions**, not all-or-nothing.
- **Rotation supported** without downtime (multiple keys active).
- **Hashed at rest** in DB (store only the hash; show full key only at creation).
- **Prefix-tagged** (`sk_live_...`) so leaks are recognizable in logs/code search.
- **Usage logging** with rate alerts on anomaly.

## Verification Patterns

For each authn/authz claim, demand evidence:

- "Authn enforced" → show the middleware/decorator chain reaching the handler.
- "Authz enforced" → show the per-object check, not the per-route check.
- "MFA on admin" → show enforcement code, not just policy doc.
- "Lockout enabled" → show counter increment + lockout check + reset on success.
