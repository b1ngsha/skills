# Threat Model — Quick Template

A 1-page threat model is enough for most reviews. Skip this only when the user already provided one.

## STRIDE Quick Reference

For each component handling untrusted input, walk through STRIDE:

| Letter | Threat | Property violated | Example |
|---|---|---|---|
| **S** | Spoofing | Authentication | Forged JWT, session fixation, impersonation |
| **T** | Tampering | Integrity | Modified request body, parameter pollution, code injection |
| **R** | Repudiation | Non-repudiation | Action with no audit log, log forging |
| **I** | Information disclosure | Confidentiality | Verbose errors, IDOR, unencrypted transport |
| **D** | Denial of service | Availability | Unbounded query, ReDoS, resource exhaustion |
| **E** | Elevation of privilege | Authorization | Authz bypass, role confusion, privilege escalation |

## Scoping Worksheet

Fill this in (10 lines maximum):

```
Assets in scope:
  - <repo / service / data store>

Trust boundaries (where untrusted input enters):
  - Public HTTP at <gateway / route prefix>
  - Webhook from <partner>
  - Mobile client (treated as untrusted)
  - File upload at <endpoint>
  - Queue consumer of <topic> (only if producer is untrusted)

Crown-jewel data:
  - <e.g. user PII, payment tokens, session cookies, internal API keys>

Adversaries in scope:
  - [ ] Unauthenticated internet attacker
  - [ ] Authenticated low-privilege user (other tenant / other user)
  - [ ] Malicious insider (employee with prod access)
  - [ ] Compromised dependency (supply chain)
  - [ ] Lost/stolen device (mobile only)

Out of scope (explicit):
  - <e.g. nation-state, physical access, side-channel>

Compliance bar (if any):
  - <PCI-DSS / HIPAA / SOC2 / GDPR>
```

## Trust Boundary Diagram (text form)

Draw the data path through the system. Each `==>` crossing a boundary is where validation/authz must happen.

```
[Internet user] ==(TLS)==> [Edge LB] --> [API gateway]
                                          |
                                          ==(internal mTLS)==> [Auth service] --> [User DB]
                                          |
                                          ==(internal mTLS)==> [Order service] --> [Order DB]
                                                                     |
                                                                     ==(queue)==> [Notification worker]

[Mobile app on user device] ==(TLS, JWT)==> [API gateway]
[Partner system]            ==(TLS, HMAC)==> [Webhook endpoint]
```

For each `==(...)==>`, ask:

- What does the receiver assume about the sender's identity? Is that assumption verified each time?
- What does the receiver assume about payload shape/content? Where is it validated?
- If this hop is bypassed (attacker connects directly to internal service), what fails open?

## Top Adversary Goals (ranked)

A short list focuses the review:

1. Exfiltrate <crown-jewel data>
2. Take over arbitrary user account
3. Escalate from low-priv user to admin
4. Cause persistent data corruption
5. Deny service for >1 hour
6. Access another tenant's data (multi-tenant only)

Findings get severity from how directly they enable a top goal, not from generic CVSS.

## When STRIDE Is Overkill

For PR-level reviews, skip STRIDE and use this micro-version:

```
For each new endpoint / handler / consumer:
  1. Where does input come from? (trust boundary)
  2. Who is allowed to call it? (authn + authz)
  3. What data does it return / mutate? (sensitivity)
  4. What happens on bad input / abuse? (validation, rate limit)
  5. What is logged? (audit + secret leakage)
```

Five questions per surface change is enough to catch ~80% of real bugs.

## Anti-Patterns in Threat Modeling

- **Modeling attackers you cannot defend against.** A nation-state with rubber-hose access is not actionable. Pick adversaries within your defensible perimeter.
- **Listing every conceivable threat.** Threat models that read like an encyclopedia get ignored. Rank ruthlessly; the top 5 matter, the rest are noise.
- **Diagramming every component.** Diagram only the components touching trust boundaries. Internal-only components without untrusted input do not need a STRIDE pass.
- **Treating the model as one-time.** Re-walk it whenever a trust boundary moves (new public endpoint, new partner, new tenant model).
