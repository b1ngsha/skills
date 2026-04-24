---
name: security-review
description: Security review for full-stack applications - threat modeling, OWASP Top 10, authentication and authorization, secrets and key management, supply chain and dependencies, transport and storage cryptography, mobile and client-side hardening, and infrastructure exposure. Use when the user asks for a security review, security audit, OWASP check, vulnerability assessment, threat model, auth or session review, secrets audit, supply-chain audit, pentest preparation, or PR review focused on security risks across backend, frontend, mobile, or infra.
---

# Security Review

Threat-model-driven security review across backend, frontend, mobile, and infrastructure. Stack-agnostic core, with stack-specific checks loaded on demand.

## Hard Rules

1. **Never declare a finding without a concrete attack path.** Each finding states: who, with what access, can do what damage, by what steps.
2. **Severity is exploitability x blast radius, not theoretical CVSS.** A "high CVSS" issue behind unreachable network = low. An "info" issue exposing prod creds = critical.
3. **Never accept "we plan to fix it" as remediation.** Either it is fixed in this review, has a tracked ticket with owner + date, or it is open.
4. **Always prefer existing tooling over manual grep.** Semgrep, Bandit, gitleaks, npm audit, pip-audit, Trivy, OSV-Scanner, Snyk, OWASP ZAP. Run them first; manual review covers the gaps.
5. **Never paste secrets into chat or commits.** Discovered credentials are referenced by location only. Treat them as compromised - rotation is part of remediation.
6. **Never give false reassurance.** Out-of-scope items are listed explicitly. "I checked" = "I ran command X and saw Y".
7. **Always verify authentication and authorization separately.** "Authn works" does not mean "authz works". Most real breaches are authz failures.

## Workflow

Copy this checklist into TodoWrite and track progress:

```
- [ ] 1. Scope & threat-model framing
- [ ] 2. Automated scan baseline
- [ ] 3. Manual deep-dive per domain
- [ ] 4. Triage with severity rubric
- [ ] 5. Verify exploitability for top findings
- [ ] 6. Report + remediation plan
```

### 1. Scope & threat-model framing

Confirm with the user once:

- **Asset boundary**: which repos / services / data stores / endpoints are in scope.
- **Trust boundaries**: where does untrusted input enter (public web, partner API, mobile client, queue, file upload)?
- **Assets to protect**: PII, credentials, payment data, IP, business logic integrity, availability.
- **Adversary model**: unauthenticated internet attacker (default), authenticated low-priv user, malicious insider, supply-chain attacker. Pick the relevant ones.
- **Compliance constraints**: PCI, HIPAA, SOC2, GDPR — these change the bar.

If the user has not produced a threat model, build a 1-page one using the STRIDE quick template in [`references/threat-model.md`](references/threat-model.md). Do not start scanning until trust boundaries are listed.

### 2. Automated scan baseline

Always run these first. Most low-hanging findings come from here, freeing manual review for logic/authz issues that scanners miss.

```bash
# Secrets in repo & history
gitleaks detect --source . --no-banner

# Dependency vulnerabilities
npm audit --audit-level=high              # JS/TS
pnpm audit --audit-level=high
pip-audit                                  # Python
osv-scanner --recursive .                  # multi-language fallback
go list -json -deps ./... | nancy sleuth   # Go

# Static analysis
semgrep --config=auto .                    # broad ruleset; tune later
bandit -r .                                # Python-specific

# Container & IaC
trivy fs .                                 # vulns + misconfigs + secrets
checkov -d .                               # Terraform/K8s misconfigs

# Infra surface (only with explicit permission for a target)
nmap -sV <host>                            # NEVER without written authorization
```

Persist scanner output to `scan-baseline.md`. Record what each tool covers and what it does not — manual review fills the gap.

### 3. Manual deep-dive per domain

Manual review focuses on issues scanners cannot find: business-logic flaws, authorization gaps, trust-boundary mistakes, cryptographic misuse with valid-looking primitives. Pick domains based on the threat model:

| Domain | Reference |
|---|---|
| Web & API surface (injection, SSRF, XSS, CSRF, headers) | [`references/web-and-api.md`](references/web-and-api.md) |
| Authentication, session, tokens, MFA, OAuth | [`references/auth-and-session.md`](references/auth-and-session.md) |
| Secrets, keys, crypto, PII, supply chain | [`references/data-and-secrets.md`](references/data-and-secrets.md) |
| Mobile/SPA storage, transport, deep links, certs | [`references/client-and-mobile.md`](references/client-and-mobile.md) |
| Infrastructure & deployment exposure | [`references/infra-and-deploy.md`](references/infra-and-deploy.md) |

Per domain, follow this loop:

1. Form an attack hypothesis from the threat model (e.g. "low-priv user can read another user's invoices via /api/invoices/:id").
2. Locate the relevant code (Grep for endpoint/handler).
3. Trace input -> validation -> authz check -> data access -> output. Note where any link is missing or weak.
4. If exploitable, draft a finding with reproducible steps. Otherwise drop the hypothesis.

### 4. Triage with severity rubric

| Severity | Criterion | Examples |
|---|---|---|
| **Critical** | Unauthenticated remote code execution, full data exfiltration, auth bypass on production | Exposed `.env`, RCE via deserialization, missing authz on admin endpoint |
| **High** | Authenticated privilege escalation, mass-assignment to sensitive fields, persistent stored XSS, exploitable injection requiring user interaction | IDOR in user-facing API, JWT secret in client, SQLi behind login |
| **Medium** | Limited-scope info disclosure, CSRF on sensitive action with user interaction, weak crypto with mitigations, missing security headers on auth pages | Verbose stack traces, `Set-Cookie` without `Secure`, missing CSP |
| **Low** | Defense-in-depth gaps, hardening recommendations, info disclosure of non-sensitive data | Server banner exposed, X-Powered-By header, weak HSTS |
| **Info** | Observations, future-proofing, not a vulnerability today | Library deprecated but not vulnerable yet |

Adjust severity by **reachability**. An RCE on a service with no network listener is low. A "low" cookie flag on the admin login page may be high.

### 5. Verify exploitability for top findings

For every Critical and High finding, produce a reproducible PoC or precise call sequence. If a PoC is not safe to run in shared environments, document the hypothetical request/response and the exact code path enabling it. Findings without a verified path get demoted.

### 6. Report + remediation plan

Use the template below. Each finding must be self-contained: a developer should be able to reproduce, fix, and verify without re-asking.

## Severity Aware Output Template

```markdown
## Scope
<assets in scope, adversary model, what was explicitly out of scope>

## Threat Model (summary)
<trust boundaries, top assets, top adversaries; full model in threat-model.md>

## Findings

### Critical
- **[domain] Title**
  - Path: <repo>/<file>:<line>
  - Trust boundary: <where untrusted input enters>
  - Attack path: <step 1 -> step 2 -> impact>
  - Reproduction: <curl / code / steps>
  - Impact: <one line>
  - Remediation: <concrete fix; not "validate input">
  - Verification: <command or test that confirms the fix>

### High
...

### Medium
...

### Low / Info
...

## Out of Scope / Not Reviewed
<explicit list - what the user must NOT assume was checked>

## Tooling Coverage
<scanners run, version, ruleset, what they cover and what they miss>

## Remediation Plan
<order of operations; rotate-credentials items first>
```

## Universal Critical Checks

Run these regardless of stack — they account for the majority of real-world breaches:

- **Secrets in repo or history**: any `.env`, `id_rsa`, `*.pem`, hardcoded API keys, DB URLs with password. Run `gitleaks detect`. If found: assume compromised, rotate, then remove.
- **Authorization on every state-changing or data-returning endpoint**: not "is the user logged in" but "is this user allowed to read/modify *this specific resource*". IDOR is the single most common real bug.
- **Input validation at trust boundary**: every external input is hostile. Validate type, range, length, charset. Do not rely on client-side validation alone.
- **SQL/ORM safety**: no string concatenation into queries. Parameterized queries or ORM only. Audit any `raw`, `extra`, `execute`, `eval`, `exec`, `subprocess.run(shell=True)`.
- **Authentication strength**: password hashing with Argon2/bcrypt/scrypt, not MD5/SHA1/PBKDF2-low-rounds. MFA on admin and high-value accounts. Session/token expiry and revocation.
- **Transport security**: HTTPS-only, HSTS, valid cert chain. No mixed content. Internal service-to-service uses mTLS or signed tokens, not "trusted network" assumption.
- **Dependencies**: lockfile present, vuln scan clean for High/Critical, no abandoned packages on critical paths.
- **Logging hygiene**: no passwords, tokens, full PII, full payment details in logs. Structured logs for security events (login, authz failure, admin action).
- **Error handling**: no stack traces, SQL errors, framework versions in production responses.
- **Default credentials and debug flags**: `DEBUG=False` in prod, no admin/admin, no sample data with real passwords.

## Anti-Patterns

- **Findings list with no attack path.** "Uses MD5" is not a finding; "MD5 used for password storage; offline cracking feasible at >100M/s on consumer GPU" is.
- **Scanner dump as report.** Triage scanner output. Suppress false positives. Group related issues. Untriaged scanner output wastes the user's time.
- **"It's behind a VPN so it's fine."** Defense in depth. The VPN is one layer. Assume each layer can fail.
- **Recommending "use a WAF" instead of fixing the bug.** WAFs are compensating controls, not remediation. Fix the code; the WAF is the tripwire.
- **Confusing authentication with authorization.** "User is logged in" tells you nothing about whether they can access this object.
- **Ignoring rate limits, lockouts, enumeration.** Brute force, credential stuffing, and account/email enumeration are real attacks; absence of controls is a finding.
- **Trusting "this field is hidden in the UI".** Anything sent to the client is observable. Anything sent from the client is forgeable.
- **Treating mobile as more secure than web.** The device is hostile. Local storage on the phone is readable, code is reverse-engineerable, traffic is interceptable on rooted/jailbroken devices.

## Reference

- [`references/threat-model.md`](references/threat-model.md) — STRIDE quick template, trust-boundary worksheet, scoping cheat sheet.
- [`references/web-and-api.md`](references/web-and-api.md) — injection, SSRF, XSS, CSRF, security headers, CORS, rate limiting.
- [`references/auth-and-session.md`](references/auth-and-session.md) — password storage, session mgmt, JWT pitfalls, OAuth flows, MFA, account recovery.
- [`references/data-and-secrets.md`](references/data-and-secrets.md) — secret storage, KMS, crypto choices, PII handling, supply-chain integrity.
- [`references/client-and-mobile.md`](references/client-and-mobile.md) — SPA/RN local storage, certificate pinning, deep-link hijacking, intent injection, WebView risks.
- [`references/infra-and-deploy.md`](references/infra-and-deploy.md) — IAM, network exposure, container hardening, IaC misconfigs, supply-chain in CI/CD.
