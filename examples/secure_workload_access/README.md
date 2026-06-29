# Demo: CyberArk Secure Workload Access (SWA / Idira)

This use case shows CyberArk **Secure Workload Access** — the SPIFFE-based
workload-identity capability that GA'd in March 2026 as part of Idira /
Secrets Manager - SaaS. The demo deploys a single-node Kind cluster on an
EC2 instance, installs the **SWA Agent** + **SPIFFE CSI driver**, and then
runs two demo workloads side-by-side:

1. **JWT-SVID → Conjur Cloud** — a pod uses its short-lived JWT-SVID
   (no static API keys, no env-var secrets) to authenticate to Conjur
   Cloud via `authn-jwt` and pull a managed secret.
2. **X.509-SVID → mTLS** — two pods establish mutual TLS using X.509
   SVIDs they fetch from the SWA Workload API. The SPIFFE CSI driver
   mounts the Workload API socket; a tiny `svid-writer` sidecar in
   each pod writes the SVID/key/bundle to a shared in-memory volume
   that the listener / dialer consumes.

Both scenarios run from the same SWA Agent, against the same trust
domain, demonstrating how one workload-identity fabric replaces both
"app password in env var" and "internal-CA cert provisioning."

## Architecture

```
                     CyberArk Idira / Secrets Manager - SaaS
                     ┌─────────────────────────────────────────┐
                     │  SWA Control Plane                      │
                     │   • Trust domain: murphys-lab.local     │
                     │   • Node attestor (k8s-psat)            │
                     │   • Workload registrations              │
                     │   • Conjur Cloud authn-jwt service      │
                     │   • Secret: data/swa-demo/secrets/…     │
                     └────────────┬────────────────────────────┘
                                  │ HTTPS (join token + attestation)
                                  ▼
   EC2 (Amazon Linux 2023) ──── Kind cluster ──── ns: cyberark-swa
   ┌──────────────────────────────────────────────────────────────┐
   │  swa-agent (DaemonSet)     spiffe-csi-driver (DaemonSet)    │
   │   • Workload API socket:   /run/spire/agent-sockets/…       │
   │   • SVID issuer for every pod that mounts the socket / CSI  │
   └──────────────────────────────────────────────────────────────┘
                ▲                                  ▲
                │ unix socket                      │ CSI mount
                │                                  │
   ns: swa-demo │                                  │
   ┌────────────┴─────────────┐     ┌──────────────┴───────────────┐
   │ secret-fetcher (Pod)     │     │ mtls-server / mtls-client    │
   │ ─ fetches JWT-SVID       │     │ ─ svid-writer sidecar pulls  │
   │ ─ authn-jwt → Conjur     │     │   X.509-SVID via socket       │
   │ ─ reads demo-api-key     │     │ ─ mutual TLS, SPIFFE ID pinned│
   └──────────────────────────┘     └──────────────────────────────┘
```

## Repository layout

```
examples/secure_workload_access/
├── README.md                                 ← you are here
├── helm-values/
│   └── (rendered by the ansible role at install time)
├── k8s-manifests/
│   ├── namespace.yaml
│   ├── jwt-svid-demo/
│   │   ├── serviceaccount.yaml
│   │   ├── configmap.yaml                    ← demo script (no secrets)
│   │   ├── configmap-conjur.yaml.example     ← copy + fill in tenant values
│   │   └── deployment.yaml
│   └── mtls-demo/
│       ├── serviceaccounts.yaml
│       ├── server.yaml
│       └── client.yaml
└── scripts/
    ├── conjur-authn-jwt-policy.yml           ← Conjur policy to load via CLI
    └── check-svid.sh                         ← post-deploy sanity checks
```

Supporting ansible bits, added to the existing `ansible/` tree:

```
ansible/
├── playbooks/
│   └── install_swa_agent.yml                 ← new
└── roles/
    └── swa_agent/                            ← new
        ├── defaults/main.yml
        ├── tasks/main.yml
        └── templates/swa-agent-values.yaml.j2
```

## Prerequisites

| Requirement | Where it comes from |
|---|---|
| CyberArk Identity / Idira tenant with **Secrets Manager - SaaS** entitled and **Secure Workload Access** enabled | CyberArk account team — SWA is a SaaS capability; you cannot install the control plane yourself |
| Conjur CLI on your laptop, authenticated to your Conjur Cloud tenant | `pip install conjur-cli`, then `conjur init` + `conjur login` |
| EC2 instance (Amazon Linux 2023) reachable over SSH, in your lab VPC | This repo's `03_ec2_compute` stack (or any AL2023 host) |
| Kind cluster on that EC2 instance | `ansible/playbooks/setup_kind_node.yml` (already in the lab) |
| Outbound HTTPS from the EC2 instance to your `*.secretsmgr.cyberark.cloud` tenant | Lab egress is already open |
| `kubectl` access to the Kind cluster from the same EC2 instance | The `kind_node` role drops a kubeconfig at `/home/ec2-user/.kube/config` |

You do **not** need a separate SPIRE server — the SWA control plane in
Secrets Manager - SaaS replaces the self-hosted SPIRE server.

---

## Manual steps in the CyberArk Idira UI (do these first)

These steps cannot be automated from this lab because they live in the
Secrets Manager - SaaS control plane.

### 1. Enable Secure Workload Access

Identity Administration → **Secrets Manager - SaaS** → **Secure Workload
Access** → **Enable**. Wait for the tile to flip to *Ready*.

### 2. Create a trust domain

SWA → **Trust Domains** → **+ Create**.

| Field | Value |
|---|---|
| Name | `murphys-lab.local` |
| Description | `Kind cluster on EC2 — demo trust domain` |

Save. This becomes the `spiffe://murphys-lab.local/…` namespace for every
identity the agent issues.

### 3. Create a node attestor for the Kind cluster

SWA → **Node Attestors** → **+ Create** → **Kubernetes PSAT** (Projected
Service Account Token).

| Field | Value |
|---|---|
| Name | `kind-on-ec2` |
| Trust domain | `murphys-lab.local` |
| Cluster name | `kind` |
| Allowed namespaces | `cyberark-swa`, `swa-demo` |
| Service-account allow-list | `cyberark-swa/swa-agent` |

Save. The agent will attest the EC2 node using a token Kubernetes mints
for the `swa-agent` ServiceAccount.

### 4. Register the demo workloads

SWA → **Workloads** → **+ Register**. Create three entries (one per
SPIFFE ID).

| SPIFFE ID | Parent (node) | Selectors |
|---|---|---|
| `spiffe://murphys-lab.local/ns/swa-demo/sa/secret-fetcher` | `kind-on-ec2` | `k8s:ns:swa-demo`, `k8s:sa:secret-fetcher` |
| `spiffe://murphys-lab.local/ns/swa-demo/sa/mtls-server`    | `kind-on-ec2` | `k8s:ns:swa-demo`, `k8s:sa:mtls-server`    |
| `spiffe://murphys-lab.local/ns/swa-demo/sa/mtls-client`    | `kind-on-ec2` | `k8s:ns:swa-demo`, `k8s:sa:mtls-client`    |

On the `secret-fetcher` registration, set **JWT audiences =
`conjur/swa-demo`** so the agent will mint JWT-SVIDs with that aud claim.

### 5. Generate a join token

SWA → **Trust Domains** → `murphys-lab.local` → **Join Tokens** →
**+ Generate**.

- TTL: `1h` (you only need it long enough for the helm install)
- Bind to node attestor: `kind-on-ec2`

Copy the token — you will pass it to ansible in step 8 as
`swa_join_token=...`. **Do not commit it.**

### 6. Configure Conjur Cloud `authn-jwt` (JWT-SVID demo only)

You can do this from the laptop using the Conjur CLI; the policy file
that does the heavy lifting is at
`scripts/conjur-authn-jwt-policy.yml`.

```bash
cd examples/secure_workload_access

# Load the policy: defines the authenticator, the host the JWT will
# represent, and the secret the host is permitted to read.
conjur policy load -f scripts/conjur-authn-jwt-policy.yml -b root

# Tell Conjur where to fetch the SWA signing keys and what to validate.
TENANT="<your-subdomain>"   # e.g. mytenant
ISSUER="https://${TENANT}.secretsmgr.cyberark.cloud"

conjur variable set -i conjur/authn-jwt/swa-demo/issuer             -v "${ISSUER}"
conjur variable set -i conjur/authn-jwt/swa-demo/jwks-uri           -v "${ISSUER}/api/swa/jwks"
conjur variable set -i conjur/authn-jwt/swa-demo/audience           -v "conjur/swa-demo"
conjur variable set -i conjur/authn-jwt/swa-demo/token-app-property -v "sub"
conjur variable set -i conjur/authn-jwt/swa-demo/identity-path      -v "data/swa-demo/workloads"

# A rotated secret the workload will fetch.
conjur variable set -i data/swa-demo/secrets/demo-api-key -v "demo-secret-$(date +%s)"
```

Finally, in the Conjur Cloud UI, enable the `authn-jwt/swa-demo`
authenticator (Authentication → **Authenticators** → toggle on).

---

## Automated steps (run from your laptop)

These assume the Kind cluster is already up (the `setup_kind_node.yml`
playbook). Replace `<ec2-ip>` and the placeholders below with your
values. The join token is the one you generated in step 5.

### 7. (Recap) bring up the Kind cluster on the EC2 instance

```bash
cd ansible
ansible-playbook \
  -i '<ec2-ip>,' \
  -e 'ansible_user=ec2-user' \
  --private-key=/path/to/us-ent-east-key.pem \
  playbooks/setup_kind_node.yml
```

### 8. Install the SWA Agent + SPIFFE CSI driver

```bash
cd ansible
ansible-playbook \
  -i '<ec2-ip>,' \
  -e 'ansible_user=ec2-user' \
  -e 'swa_tenant_subdomain=<your-subdomain>' \
  -e 'swa_join_token=<token-from-step-5>' \
  -e 'swa_trust_domain=murphys-lab.local' \
  --private-key=/path/to/us-ent-east-key.pem \
  playbooks/install_swa_agent.yml
```

The play does three things:

1. `helm repo add cyberark-swa …` + `helm repo update`
2. `helm upgrade --install swa-agent` into the `cyberark-swa` namespace
   with values rendered from your trust-domain / join-token inputs
3. `helm upgrade --install spiffe-csi-driver` so the X.509 demo can
   mount SVIDs as files

When it finishes you should see the agent + csi pods `Running`.

### 9. Deploy the demo workloads

From the EC2 instance (`ssh ec2-user@<ec2-ip>`), pull this repo down or
`scp` the manifests over, then:

```bash
cd examples/secure_workload_access

kubectl apply -f k8s-manifests/namespace.yaml

# --- JWT-SVID demo ---------------------------------------------------
cp k8s-manifests/jwt-svid-demo/configmap-conjur.yaml.example \
   k8s-manifests/jwt-svid-demo/configmap-conjur.yaml
# Edit configmap-conjur.yaml: set your tenant URL, host id, secret id.
# (configmap-conjur.yaml is .gitignored via *.yaml.example only — make
# sure it does not get committed.)

kubectl apply -f k8s-manifests/jwt-svid-demo/serviceaccount.yaml
kubectl apply -f k8s-manifests/jwt-svid-demo/configmap.yaml
kubectl apply -f k8s-manifests/jwt-svid-demo/configmap-conjur.yaml
kubectl apply -f k8s-manifests/jwt-svid-demo/deployment.yaml

# --- X.509-SVID mTLS demo --------------------------------------------
kubectl apply -f k8s-manifests/mtls-demo/serviceaccounts.yaml
kubectl apply -f k8s-manifests/mtls-demo/server.yaml
kubectl apply -f k8s-manifests/mtls-demo/client.yaml
```

---

## Running the demo

### Demo 1 — JWT-SVID → Conjur Cloud secret fetch

```bash
kubectl -n swa-demo logs -f deploy/secret-fetcher
```

Expected output, repeating every 60s:

```
[secret-fetcher] requesting JWT-SVID from the SWA Workload API
[secret-fetcher] exchanging JWT-SVID for a Conjur access token
[secret-fetcher] reading secret data/swa-demo/secrets/demo-api-key
[secret-fetcher] retrieved secret value (length=27)
[secret-fetcher] first 4 chars: demo********
```

**The talking point:** the pod has no API key, no service account file,
no bootstrapped secret. It walks up to the SWA Workload API socket on
the node, gets a JWT signed by the SWA trust domain, and Conjur Cloud
trusts that signature because of the `authn-jwt` configuration. Rotate
the secret in Conjur and the next loop iteration sees the new value
within 60 seconds.

To prove the kill-switch story:

1. In the SWA UI, delete (or expire) the workload registration for
   `spiffe://murphys-lab.local/ns/swa-demo/sa/secret-fetcher`.
2. Watch the pod's logs — the next `spire-agent api fetch jwt` call
   fails because the agent will not mint a SVID for an unregistered
   workload, so no secret read happens.

### Demo 2 — X.509-SVID mutual TLS

```bash
kubectl -n swa-demo exec deploy/mtls-server -c listener -- ls -l /var/run/svids
```

You should see `svid.0.pem`, `svid.0.key`, and `bundle.0.pem`. None of
those are baked into the image — the `svid-writer` sidecar fetched them
through the Workload API socket the SPIFFE CSI driver mounted at
`/spiffe-workload-api`.

```bash
kubectl -n swa-demo logs -f deploy/mtls-client
```

Expected output every 30s:

```
[mtls-client] dialing https://mtls-server.swa-demo.svc:8443 with our SPIFFE cert
HTTP/1.1 200 OK
Content-Type: text/plain

hello from mtls-server
```

**The talking point:** neither pod was provisioned with a TLS cert.
Each SVID was minted in-cluster by SWA, rotates on a short TTL, and is
validated against the SPIFFE trust bundle the same agent hands out.
Delete the `mtls-client` workload registration in SWA, wait for the
next `svid-writer` cycle (or kill the sidecar pod to refresh sooner),
and the handshake fails — proving SWA is the policy decision point for
*who can talk to whom*, not just *who gets a cert*.

### Quick health check

```bash
./scripts/check-svid.sh
```

(Run from any host with kubectl pointed at the cluster.)

---

## Cleanup

```bash
# Demo workloads
kubectl delete -f k8s-manifests/mtls-demo/
kubectl delete -f k8s-manifests/jwt-svid-demo/deployment.yaml
kubectl delete -f k8s-manifests/jwt-svid-demo/configmap-conjur.yaml --ignore-not-found
kubectl delete -f k8s-manifests/jwt-svid-demo/configmap.yaml
kubectl delete -f k8s-manifests/jwt-svid-demo/serviceaccount.yaml
kubectl delete -f k8s-manifests/namespace.yaml

# Agent + CSI driver
helm -n cyberark-swa uninstall spiffe-csi-driver
helm -n cyberark-swa uninstall swa-agent
kubectl delete namespace cyberark-swa

# SWA UI — delete the workload registrations, node attestor, and trust
# domain you created in steps 2-5 if you want to fully reset.

# Conjur — destroy the policy (it is non-destructive by default; the
# branch deletion removes the host and variables):
conjur policy delete -b root -i conjur/authn-jwt/swa-demo
conjur policy delete -b root -i data/swa-demo
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `swa-agent` pod is `CrashLoopBackOff` with `attestation failed` | Node attestor in SWA doesn't match the cluster name or namespace | Step 3 — verify cluster name `kind`, namespace `cyberark-swa`, SA `swa-agent` |
| `spire-agent api fetch jwt` returns `no identity issued` | Workload not registered in SWA, or selectors don't match the pod | Step 4 — selectors must include `k8s:ns:<namespace>` and `k8s:sa:<serviceaccount>` |
| `secret-fetcher` gets `401` from Conjur on `/authenticate` | `audience` mismatch, `token-app-property` wrong, or authenticator disabled | Step 6 — `audience` in Conjur must equal `JWT_AUDIENCE` in the configmap (`conjur/swa-demo`); enable the authenticator in the Conjur UI |
| `secret-fetcher` gets `403` from Conjur on `/secrets/...` | Host not granted on the variable | Re-load `scripts/conjur-authn-jwt-policy.yml`; the `!permit` block must list the host |
| `mtls-server` pod stuck in `ContainerCreating` with `csi.spiffe.io … not found` | The CSI driver Helm install was skipped or failed | Re-run `install_swa_agent.yml` with `-e swa_install_csi_driver=true` (the default) |
| `svid-writer` sidecar logs `no identity issued` repeatedly | Pod's workload registration missing / selectors wrong | Re-check step 4; selectors must match `k8s:ns:swa-demo` + `k8s:sa:<server\|client>` |
| `mtls-client` gets `SSL_ERROR_SYSCALL` from curl | Server's SVID hasn't been written to `/var/run/svids` yet, or its registration is missing | `kubectl -n swa-demo exec deploy/mtls-server -c listener -- ls /var/run/svids` to confirm files exist; then check the server's registration in SWA |
| Join token install fails with `token expired` | The 1h join token aged out before you ran the playbook | Generate a fresh token (step 5) and rerun step 8 |

## Notes on what was intentionally left out

- **No Terraform module.** SWA's control-plane resources (trust domains,
  node attestors, workload registrations, join tokens) are not yet
  exposed by the `cyberark/idsec` provider. When that lands, the manual
  UI steps 2–5 become a Terraform module slotted next to the existing
  `examples/identity/`.
- **No production hardening.** This demo runs the agent under
  `hostPath` mounts and packs server + client into the same Kind node.
  For production you would deploy the agent per-node as a DaemonSet on
  every workload pool, scope node attestors per cluster, and use a
  shorter SVID TTL.
- **No `terraform.tfvars` management.** Because nothing here uses
  Terraform, this example is intentionally absent from
  `scripts/config.sh`. The only secret is the `swa_join_token`, which
  is short-lived and passed via `-e` on the ansible command line.
