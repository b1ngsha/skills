# Infrastructure & Deployment

Cloud, container, and CI/CD checks. Most findings here come from Trivy / Checkov / cloud-provider scanners; manual review covers IAM logic, network exposure intent, and incident response readiness.

## Cloud IAM

### Principles

- **Least privilege per identity.** No `Action: "*"`, no `Resource: "*"` in production.
- **No long-lived user credentials in workloads.** Use IAM roles / service accounts / workload identity (IRSA, GKE Workload Identity, Azure Managed Identity).
- **Per-environment separation.** Prod credentials never reachable from dev/staging.
- **MFA on human accounts**, especially with `iam:*`, `sts:AssumeRole`, billing, KMS.
- **Break-glass accounts** documented, audited, and locked behind step-up auth.

### Common IAM bugs

| Pattern | Risk |
|---|---|
| `"Action": "*"` on any policy | Total takeover scope |
| `"Principal": "*"` on resource policy without conditions | Public access to bucket / queue / topic |
| `iam:PassRole` with `Resource: "*"` | Privilege escalation to any role |
| Wildcard role trust policy (`Principal: { AWS: "*" }`) | Anyone with an AWS account can assume |
| `sts:AssumeRole` allowed without `ExternalId` for cross-account | Confused deputy |
| Long-lived access keys (>90d) | Likely leaked / forgotten |
| Inline policies vs managed | Hard to audit; prefer managed |
| IAM user with API key + console password + no MFA | Pivot point |

Detection:

```bash
# AWS - find wildcard policies
aws iam list-policies --scope Local | jq '.Policies[].Arn' | xargs -I {} \
  aws iam get-policy-version --policy-arn {} --version-id v1 | rg '"\*"'

# Trust policies
aws iam list-roles | jq '.Roles[] | select(.AssumeRolePolicyDocument.Statement[].Principal.AWS == "*")'

# Stale access keys
aws iam list-users | jq -r '.Users[].UserName' | while read u; do
  aws iam list-access-keys --user-name "$u"
done
```

GCP equivalents: `gcloud projects get-iam-policy`, look for `roles/owner`, `roles/editor`, `allAuthenticatedUsers`, `allUsers`.

## Network Exposure

- **Default deny** at security group / firewall / NSG. Open inbound only what is needed, only from where it is needed.
- **No `0.0.0.0/0` on**: SSH (22), RDP (3389), DB ports (3306, 5432, 27017, 6379, 9200), admin UIs (Kubernetes API, etcd, Redis, Elasticsearch, Kibana, Grafana).
- **Outbound restrictions** for workloads handling user-supplied URLs (SSRF defense at network layer): block egress to RFC1918, link-local (169.254), cloud metadata (`169.254.169.254`), and unauthorized external hosts.
- **Public buckets**: S3, GCS, Azure Blob — every bucket reviewed for public read/write. Block-public-access enabled at account level by default.
- **Public databases**: any DB with public IP is a finding unless explicitly justified (e.g. analytics with strong auth).
- **VPC peering / Transit Gateway** routes audited — unintentional cross-environment connectivity.
- **TLS termination**: where does TLS terminate? Internal hop after termination is plaintext unless mTLS or service mesh enforces it.

Detection:

```bash
# AWS public security groups
aws ec2 describe-security-groups | jq '.SecurityGroups[] | {GroupId, IpPermissions: [.IpPermissions[] | select(.IpRanges[].CidrIp == "0.0.0.0/0")]}'

# Public S3 buckets
aws s3api list-buckets | jq -r '.Buckets[].Name' | while read b; do
  aws s3api get-bucket-public-access-block --bucket "$b" 2>&1
done

# Open ports from outside
nmap -Pn -p- -T4 <public-ip>   # only with written authorization
```

## Container & Kubernetes

### Image hygiene

- Pin base image by digest (`@sha256:...`), not tag.
- Minimal base (distroless, Alpine, slim).
- Non-root `USER` set explicitly.
- No build secrets in final image (multi-stage build, no `ARG SECRET`).
- `trivy image <image>` clean of High/Critical.
- Signed images (`cosign sign`) verified on admission.

### Runtime

- `securityContext`:
  - `runAsNonRoot: true`
  - `readOnlyRootFilesystem: true`
  - `allowPrivilegeEscalation: false`
  - `capabilities: { drop: ["ALL"] }`, add only what is needed
  - `seccompProfile: { type: RuntimeDefault }`
- `Pod`:
  - No `hostNetwork`, `hostPID`, `hostIPC` unless required
  - No `hostPath` mounts unless required (mount is read-only when possible)
  - `automountServiceAccountToken: false` if pod does not call K8s API
- **Resource limits** on every container (CPU + memory) — DoS protection from resource exhaustion.

### NetworkPolicies

Cluster default-deny. Each namespace explicitly allows the ingress/egress it needs. Without NetworkPolicies, lateral movement inside the cluster is unrestricted.

### Secrets

- Use a secret manager (Vault + agent, AWS Secrets Manager + CSI driver, External Secrets Operator) — not raw `Secret` objects when possible.
- Encryption at rest for etcd (`--encryption-provider-config` with KMS).
- RBAC restricts `get`/`list` on `secrets` to specific service accounts.

### Admission control

- OPA Gatekeeper / Kyverno / native Pod Security Admission enforces baselines.
- Image signature verification (`cosign verify` via policy controller).
- No privileged pods outside `kube-system`.

Detection (Checkov / kube-bench / kube-score):

```bash
checkov -d k8s/
kube-bench run --targets master,node    # CIS benchmarks
kube-score score k8s/*.yaml
```

## Infrastructure as Code

```bash
checkov -d terraform/
tfsec terraform/
trivy config terraform/
```

Common Terraform/CloudFormation findings:

- Buckets without `block_public_access`.
- Security groups with `0.0.0.0/0` ingress on sensitive ports.
- KMS keys without rotation enabled.
- Logging disabled (CloudTrail, VPC flow logs, ALB access logs, S3 access logs).
- Default encryption disabled on EBS / RDS / S3.
- IAM policies with `*` actions.
- Public RDS / ElastiCache / Elasticsearch.

State files:

- Stored in remote backend with encryption + versioning + access control (S3 + DynamoDB lock with restricted IAM).
- **Never** committed to repo — they contain plaintext secrets.

## CI/CD Pipeline

- **Pinned action versions by SHA**, not floating tags.
- **Least-privilege workflow tokens**: `permissions:` block, default `contents: read`.
- **Secrets scoped per environment**, not org-wide. Production secrets unavailable to PR builds from forks.
- **PR builds from forks** do not have access to secrets (`pull_request` event default; reject `pull_request_target` patterns that auto-checkout fork code).
- **Branch protection**: required reviews, required status checks, no force-push to protected branches.
- **Signed commits / signed tags** for release branches in high-assurance contexts.
- **Build provenance**: SLSA Level 2+ for release artifacts (`cosign attest`, GitHub OIDC tokens for keyless signing).
- **Self-hosted runners isolation**: never run untrusted PR code on a runner with network/credential access to production.

## Logging, Monitoring, Alerting

Security observability is the difference between a 1-hour incident and a 6-month one.

- **Auth events logged**: login success/fail, MFA challenges, token issuance, password resets, admin actions.
- **Authz failures logged**: 403s with user + resource + action.
- **Sensitive operations logged**: data exports, role changes, key rotations, billing events, deletes.
- **Logs immutable** (S3 with object lock, write-once buckets) for the retention window.
- **Logs centralized** off-host so a compromised host cannot wipe its own logs.
- **Log integrity**: signed/HMACed log batches for forensic-grade audit.
- **Alerts on**:
  - Spike in 401/403/5xx
  - First-time-from-this-IP login on admin accounts
  - Multiple failed MFA
  - IAM changes (especially role/policy creation, key creation)
  - Egress to unusual destinations
  - Disabled security tooling (CloudTrail off, GuardDuty findings dismissed)
- **Runbooks** exist for top alerts; on-call can act in <15 minutes.

## Incident Response Readiness

Quick checks (these are review items even when no incident is active):

- Documented contact path for security reports (`security.txt`, security@ alias).
- Known evidence preservation procedure (snapshot, isolate, do not power off).
- Credential rotation procedure that can complete in <1 hour.
- Customer notification template aligned with breach-notification deadlines (GDPR 72h, state laws).
- Recent tabletop or live exercise.

## Verification Commands

```bash
# Cloud baseline
aws-nuke --version            # for ephemeral env teardown verification
prowler -p <profile>          # broad AWS audit
scout-suite --provider aws    # alternative

# Kubernetes
kube-bench run
kube-hunter --remote <api-server>   # only with authorization

# IaC
checkov -d .
tfsec .

# Container
trivy image <image>
docker scout cves <image>

# Secrets in CI logs
gh run list --limit 50 --json databaseId | jq -r '.[].databaseId' | while read id; do
  gh run view "$id" --log | gitleaks detect --pipe --no-banner
done
```
