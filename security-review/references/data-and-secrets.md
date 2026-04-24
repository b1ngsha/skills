# Data, Secrets, Crypto, Supply Chain

## Secrets Management

### What counts as a secret

- API keys, OAuth client secrets, database URLs with passwords
- Private keys (TLS, signing, SSH), JWT signing keys, encryption keys
- Webhook signing secrets, internal service-to-service tokens
- Cloud provider credentials (AWS access keys, GCP service account JSON, Azure SP creds)
- Encryption salts/peppers used in password hashing (salts are per-record; pepper is global secret)

### Where they leak

| Location | Detection |
|---|---|
| Repo files | `gitleaks detect --source .` |
| Git history | `gitleaks detect --source . --log-opts="--all"` |
| `.env` committed | `rg --hidden -l '\.env$'` and verify `.gitignore` |
| Client bundles (JS, RN) | grep built bundle in `dist/` / `build/` |
| Mobile binaries | `strings app.apk | rg -i 'api[_-]?key\|secret\|password'` |
| Logs | `rg -i 'password|token|secret' logs/` |
| Error responses | trigger errors and inspect responses |
| CI logs | scan recent CI/CD logs for printed env vars |
| Container images | `trivy image <image>` includes secret scan |
| Docs / README / Postman collections | manual inspection |

### Storage

- **Never** in repo, in env vars set via Dockerfile, in CI YAML, in client code.
- **Use** a secret manager: AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault, sealed-secrets for K8s.
- **Inject** at runtime via env or mounted file; rotate on schedule and on suspected leak.
- **Encrypt at rest** even in the secret manager (most do by default; verify KMS key is customer-managed for high-sensitivity).

### Discovered leaks — remediation order

1. **Rotate immediately** — assume compromised the moment it touched a public surface.
2. Remove from current code.
3. Purge from git history (`git filter-repo` or `BFG`); force-push; notify all clones.
4. Audit logs for usage during exposure window.
5. Add to secret scanner ruleset to prevent recurrence.

Removing a secret from the latest commit without rotation is **not remediation** — git history persists.

## Cryptography Choices

| Use case | Recommended | Avoid |
|---|---|---|
| Password hashing | Argon2id, bcrypt | MD5, SHA-1, SHA-256 plain |
| Symmetric encryption | AES-256-GCM, ChaCha20-Poly1305 | AES-CBC without HMAC, AES-ECB, DES, 3DES, RC4 |
| Asymmetric encryption | X25519 + ChaCha20-Poly1305, RSA-OAEP-SHA256 (>=3072) | RSA-PKCS1v1.5, RSA-1024 |
| Signing | Ed25519, ECDSA-P256, RSA-PSS (>=3072) | RSA-PKCS1v1.5, ECDSA-P192, DSA |
| MAC | HMAC-SHA256, Poly1305 | CRC, custom |
| Hash (non-password) | SHA-256, SHA-3, BLAKE2/3 | MD5, SHA-1 |
| Random | OS CSPRNG (`secrets`, `crypto.randomBytes`, `/dev/urandom`) | `random`, `Math.random`, `time()` seed |
| Key derivation | HKDF | ad-hoc concat + hash |

### Common crypto bugs

- **Hard-coded keys** in source: a key in code = no key.
- **Key reuse across purposes**: same key for encryption and signing → vulnerabilities. Derive per-purpose subkeys via HKDF.
- **IV/nonce reuse with AES-GCM**: catastrophic — leaks plaintext XOR and forgery key. Use random 96-bit nonce per message and assume birthday limit ~2^32 messages per key.
- **AES-CBC without HMAC**: malleable. Use authenticated encryption (GCM, ChaCha20-Poly1305).
- **ECB mode**: not encryption. Detectable patterns in ciphertext.
- **Padding oracle**: error responses that distinguish "bad padding" from "bad MAC" enable plaintext recovery. Use authenticated encryption + constant-time MAC verification.
- **Math.random for tokens**: predictable. Use CSPRNG.
- **Wrong comparison**: token check via `==` leaks via timing. Use constant-time compare.
- **JWT crypto issues**: see `auth-and-session.md`.

Detection:

```bash
rg "AES\.new\([^,]+,\s*AES\.MODE_(ECB|CBC)\b|Cipher\.getInstance\(['\"]AES/ECB" 
rg "Math\.random|random\.random\(\).*token|new Random\(\)\.next" 
rg "PKCS1_v1_5|RSA-PKCS1v15"
```

## PII and Sensitive Data Handling

- **Data minimization**: store only what is needed; delete on schedule.
- **Encryption at rest**: full-disk + DB-level for high-sensitivity columns (use deterministic encryption only when required for search; otherwise random IV).
- **Encryption in transit**: TLS 1.2+ everywhere, including internal hops.
- **Tokenization** for payment data (PAN) — use a PCI-compliant vault, do not store PAN.
- **Field-level access control**: SSN, DOB, payment data → restricted columns with audit trail.
- **Logs**: never log full passwords, tokens, full PAN, full SSN. Mask: `4***-****-****-1234`.
- **Backups** are in scope: same encryption + access control as primary store.
- **Data export endpoints** (GDPR/DSAR): rate-limit, authenticate strongly, log every export.
- **Right-to-deletion**: actually deletes (not soft-delete) from primary, replicas, backups within retention window. Document the implementation.

## Insecure Deserialization

Deserializing untrusted data into language objects → RCE.

| Language / format | Safe? | Notes |
|---|---|---|
| Python `pickle` from untrusted | NO | RCE on `loads`. Replace with JSON or a schema lib. |
| Python `yaml.load` (without `SafeLoader`) | NO | Use `yaml.safe_load`. |
| Java `ObjectInputStream` | NO unless allowlist | Many gadget chains exist. |
| .NET `BinaryFormatter` | NO | Microsoft deprecated for security reasons. |
| Ruby `Marshal.load` | NO | RCE potential. |
| PHP `unserialize` | NO unless `allowed_classes=false` | Object injection / POP chains. |
| JSON (any lang) | Yes — pure data | Validate schema; do not eval. |
| Protobuf, MessagePack | Yes — pure data | |

Detection:

```bash
rg "pickle\.loads?\(|yaml\.load\([^,)]+\)$|ObjectInputStream|BinaryFormatter|Marshal\.load|unserialize\("
```

## Supply Chain

### Lockfiles & integrity

- Lockfile committed (`package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`, `go.sum`).
- Reproducible installs in CI (`npm ci`, `pnpm install --frozen-lockfile`, `pip install --require-hashes`).
- Hash-pinned dependencies for high-value services (`pip-tools` with `--generate-hashes`).

### Vulnerability scanning

```bash
npm audit --audit-level=high
pnpm audit --audit-level=high
yarn npm audit --severity high
pip-audit
poetry export -f requirements.txt | pip-audit -r /dev/stdin
osv-scanner --recursive .
trivy fs .
```

Triage: filter by reachability — a vuln in a transitive dev-only dep is lower than one in a runtime auth library.

### Dependency confusion

Internal packages with names that could be claimed on the public registry. Mitigations:

- Scoped packages (`@org/*`) with registry pinned to internal.
- `.npmrc` / `pip.conf` configured to refuse public for internal scopes.
- For pip: use `--index-url` (replaces, not extends) for internal packages.

### Typosquatting & install-time scripts

- Audit new dependencies before adding (download counts, age, maintainer history, recent ownership transfers).
- Disable lifecycle scripts where possible (`npm install --ignore-scripts`); allowlist trusted packages that need them.
- Use `socket.dev`, `snyk`, or similar for transitive analysis.

### CI/CD pipeline integrity

- Pinned action versions by SHA, not floating tags (`uses: actions/checkout@<sha>`).
- Least-privilege GitHub Actions tokens (`permissions:` block, default `contents: read`).
- Secrets scoped per environment; production secrets not exposed to PR builds.
- Branch protection: required reviews, required status checks, no force-push to protected branches, signed commits if required.
- Build provenance (SLSA / `cosign attest`) for release artifacts in high-assurance contexts.

### Container images

- Base image pinned by digest, not tag (`FROM python:3.12.4@sha256:...`).
- Minimal base (distroless, Alpine, slim) — fewer packages, smaller attack surface.
- Multi-stage build: build deps not in final image.
- Run as non-root user; `USER 1000:1000`.
- `trivy image <image>` for vulns + secrets + misconfigs.
- Sign images (`cosign sign`) for prod; verify on deploy.
