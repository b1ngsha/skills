# Client & Mobile

The device is hostile. Treat all client storage as readable, all client code as reverse-engineerable, all client traffic as interceptable on rooted/jailbroken devices.

## Universal Client Rules

- **No secrets in client code or bundles.** API keys, signing keys, server-side credentials never ship to the client. If the client must call a third-party API directly, use a backend proxy or short-lived token issued by your backend.
- **Client-side validation is UX, not security.** Re-validate every input on the server.
- **Authorization happens server-side.** Hiding a UI button does not protect the underlying endpoint.
- **Anything in the request from the client is forgeable.** Tamper-resistant only when signed by a server-issued secret the client cannot extract.

## Web SPA (React, Vue, Svelte)

### Token storage

| Where | Risk | Verdict |
|---|---|---|
| `localStorage` / `sessionStorage` | Stealable by any XSS | Avoid for auth tokens |
| Memory only (variable) | Lost on refresh; mitigated by silent refresh | Best for access tokens |
| `HttpOnly; Secure; SameSite` cookie | Not JS-readable; CSRF risk on cross-origin | Best when CSRF protection in place |
| IndexedDB | Same risk as `localStorage` | Avoid for tokens |

Recommended: short-lived access token in memory + refresh token in `HttpOnly` cookie + CSRF token for state-changing requests.

### XSS hardening

- Strict CSP (no `'unsafe-inline'`, no `'unsafe-eval'`); use nonces for required inline scripts.
- Auto-escaping templating; explicit deny on `dangerouslySetInnerHTML` / `v-html` for untrusted content.
- DOMPurify (or framework equivalent) for any rich-text rendering.
- Trusted Types policy where supported.

### Third-party scripts

- Subresource Integrity (`integrity="sha384-..."`) on every CDN-loaded script and stylesheet.
- Pin versions; do not load `latest`.
- Audit each tag manager / analytics script for what it accesses (DOM scraping reads form fields including passwords if not blocked).
- CSP `script-src` allowlist limits damage from compromised tag manager.

### postMessage

- Always check `event.origin` against an allowlist before processing.
- Never use `'*'` as `targetOrigin` when sending sensitive data.

### Service Workers

- Scope tightly; a SW with broad scope intercepts all fetches in scope.
- Verify `Service-Worker-Allowed` header is not set permissively.

## React Native / Mobile

### Local storage

| Storage | Encryption | Use for |
|---|---|---|
| `AsyncStorage` (RN) | None | Non-sensitive UI state only |
| `expo-secure-store` (RN/Expo) | iOS Keychain / Android Keystore | Tokens, secrets |
| iOS Keychain (native) | Hardware-backed | Tokens, secrets |
| Android Keystore + EncryptedSharedPreferences | Hardware-backed (StrongBox where available) | Tokens, secrets |
| MMKV with encryption key | Encrypted with provided key | Bulk encrypted state (key must come from secure store) |

Detection:

```bash
rg "AsyncStorage\.setItem.*['\"](token|secret|password|key)" 
rg "@react-native-async-storage" --files-with-matches  # then audit each call
```

### Transport security

- HTTPS enforced; reject self-signed in production.
- **Certificate pinning** for high-value apps (banking, healthcare). Pin to public-key SPKI hash; rotate with backup pins. iOS: `NSAppTransportSecurity` + URLSessionDelegate; Android: `network-security-config.xml` or OkHttp `CertificatePinner`. RN: `react-native-ssl-pinning`.
- Disable cleartext traffic: iOS ATS, Android `usesCleartextTraffic="false"`.
- App Transport Security exceptions justified per-domain in code review.

### Deep links & URL schemes

| Risk | Mitigation |
|---|---|
| Custom scheme hijacking (any app can register `myapp://`) | Use Universal Links (iOS) / App Links (Android) — verified by domain |
| Sensitive params in URL (token, password) end up in logs/clipboard/history | Never send credentials via deep link |
| Open redirect from deep link to webview | Validate target URL against allowlist |
| Auto-execute action on link receipt | Require user confirmation for state-changing actions |

### WebView

- **Disable JS** unless required (`javaScriptEnabled = false`).
- **Disable `allowFileAccess`, `allowFileAccessFromFileURLs`, `allowUniversalAccessFromFileURLs`** (Android).
- **JavaScript bridge minimization**: every method exposed via `addJavascriptInterface` (Android) or `messageHandlers` (iOS) is an attack surface. Allowlist origins that may post messages.
- **Load only HTTPS**; do not load arbitrary user-supplied URLs.
- **Cookies & storage** of WebView are separate from main app; review what is shared.

### Inter-app (Android)

- **Exported components** (`exported="true"`): every Activity/Service/Receiver/Provider with `exported="true"` is callable by any other app. Audit each — many are unintentionally exported.
- **Intent injection**: `PendingIntent` with mutable extras callable by other apps to take action as your app. Use `FLAG_IMMUTABLE`.
- **Implicit intents** carrying sensitive data → any app can intercept. Use explicit intents (component name set).
- **ContentProvider** permissions: read/write permissions per-URI.

### iOS specifics

- **App Groups**: shared UserDefaults / file containers between app and extensions — same access control as in-process data.
- **URL Schemes**: declare in `Info.plist`; verify with `LSApplicationQueriesSchemes` if querying others.
- **Universal Links** preferred over custom schemes (verified ownership).
- **Pasteboard**: do not put secrets on pasteboard; if needed, set `expirationDate` and `localOnly = true`.
- **Screenshot/snapshot privacy**: blur sensitive screens during backgrounding (`applicationWillResignActive` overlay).

### Anti-tamper / detection

For high-value apps only — these are deterrents, not defenses:

- Jailbreak/root detection (`expo-device` is **not** sufficient; use a vetted lib, expect bypass).
- Code obfuscation for release builds (`enableProguardInReleaseBuilds`, Hermes bytecode for RN).
- Repackaging detection (signature check at runtime).
- Frida / Objection detection.

Do not rely on these for security; they raise the bar against casual attackers and lower it against motivated ones (false sense of security).

### Sensitive data in build artifacts

```bash
# RN bundle inspection
unzip -p app-release.apk assets/index.android.bundle | rg -i "api[_-]?key|secret|password|token"
unzip -p app.ipa Payload/*.app/main.jsbundle | rg -i "api[_-]?key|secret"

# Android strings
strings app-release.apk | rg -i "api[_-]?key|secret|password" | head

# iOS strings
strings App | rg -i "api[_-]?key|secret|password" | head
```

Common findings: dev API keys shipped to prod, debug endpoints reachable, third-party SDK keys with broader-than-needed scope.

### Push notifications

- **Tokens are not secrets** but are user-identifying — same handling as PII.
- **Payload contents**: do not include sensitive data in notification body (visible on lock screen, logged by OS).
- **Notification action** that performs state change must require app-foreground auth.

## Browser Extension (if in scope)

- `manifest_version: 3` (MV2 deprecated).
- Minimum permissions; avoid `<all_urls>` host permissions.
- Content scripts run in isolated world; do not pass tokens to page context.
- `web_accessible_resources` minimal — exposed resources can be embedded by any site.
- CSP: extension default is strict; do not weaken with `'unsafe-eval'`.
