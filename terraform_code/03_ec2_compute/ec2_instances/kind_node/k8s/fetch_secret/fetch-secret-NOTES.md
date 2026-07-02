# fetch-secret — demo tool notes

## What it does
A CLI/Job that demonstrates the full SWA -> Secrets Manager SaaS round trip
in one shot:

1. Fetches a JWT-SVID from the SWA Agent (same Workload API call as
   swa-probe).
2. POSTs it to Secrets Manager's JWT authenticator endpoint to get a
   short-lived access token.
3. Uses that access token to GET one or two secrets (password, optionally
   username) and prints them to stdout.

Built against the documented Secrets Manager SaaS REST APIs:
- Authenticate: `POST /api/authn-jwt/{service-id}/conjur/authenticate`
- Retrieve a secret: `GET /api/secrets/conjur/variable/{identifier}`
- Pattern reference: "Authenticate AI agents with JWT SVIDs (SPIFFE)" in the
  Secrets Manager SaaS docs — this is literally the documented pattern for a
  SPIFFE-identified workload, not something improvised.

**This is a demo tool.** It deliberately prints secret values in plain text
to stdout so you can show someone the round trip worked live. Don't reuse
this pattern in anything real — a production consumer should use the
returned access token to talk to whatever it actually needs, not print
credentials to a terminal.

## Before you can run this, you need to finish the Secrets Manager side
The probe work proved your `sub` value is real and cryptographically valid:
```
spiffe://kind.local/kind-node-group/ns/swa-probe/sa/swa-probe
```
This tool can't do anything until you've configured Secrets Manager to trust
that identity:

1. **Create a JWT authenticator** (UI or CLI) with:
   - JWKS URI: your SWA trust domain's OIDC discovery endpoint — check what
     your SWA Server's bundle/JWKS endpoint actually is; may not be the
     generic `oidc-discovery.<spiffe-server>/keys` example from the docs
     since your setup uses `bundleSourceUrl:
     https://murphyslab.secretsmgr.cyberark.cloud/api/swa/trust-domains/kind.local/.well-known/ca-bundles`
     — the JWT signing keys are likely served from a sibling path under that
     same trust-domain URL. Confirm the exact JWKS path before setting this.
   - Issuer: `https://murphyslab.secretsmgr.cyberark.cloud/api/swa/trust-domains/kind.local`
     (this is your probe's confirmed `iss` claim — use it verbatim)
   - Token app property: `sub`
   - Identity path: pick a branch, e.g. `data/spiffe-apps`

2. **Create a workload (host)** named exactly
   `spiffe://kind.local/kind-node-group/ns/swa-probe/sa/swa-probe` under that
   branch, with annotation:
   ```
   authn-jwt/<your-service-id>/sub: spiffe://kind.local/kind-node-group/ns/swa-probe/sa/swa-probe
   ```

3. **Grant that workload read/execute access** to whatever secret
   variable(s) you want this tool to fetch (e.g. `data/demo/db/password`).

4. **Create the actual secret variable(s)** and set their values if you
   haven't already (`conjur variable set -i data/demo/db/password -v ...`).

## Running it
Fill in the three `CHANGE-ME` values in `fetch-secret-job.yaml`
(`SECRETS_MGR_SUBDOMAIN`, `SECRETS_MGR_JWT_SERVICE_ID`,
`SECRETS_MGR_PASSWORD_VAR`), then:

```bash
go mod tidy                                  # generate go.sum (needs real network)
docker build -t fetch-secret:0.1.0 -f fetch-secret-Dockerfile .
kind load docker-image fetch-secret:0.1.0 --name <your-cluster-name>
kubectl apply -f fetch-secret-job.yaml
kubectl -n swa-probe logs job/fetch-secret -f
```

Expect something like:
```
[fetch-secret] step 1/3: fetching JWT-SVID from SWA Agent | socket=/tmp/swa-agent/public/api.sock audience="conjur"
[fetch-secret]   got JWT-SVID for sub=spiffe://kind.local/kind-node-group/ns/swa-probe/sa/swa-probe (484 bytes)
[fetch-secret] step 2/3: authenticating to Secrets Manager | tenant=murphyslab service-id=spiffe-auth
[fetch-secret]   authenticated; received short-lived access token (...)
[fetch-secret] step 3/3: retrieving secret(s) from Secrets Manager

========================================
 Secret retrieved from Secrets Manager SaaS
========================================
 Workload (SPIFFE ID): spiffe://kind.local/kind-node-group/ns/swa-probe/sa/swa-probe
 Username : demo-user
 Secret   : ****actual-password-value****
========================================
```

## Re-running for a live demo
Since it's a Job, re-running means deleting and re-applying:
```bash
kubectl -n swa-probe delete job fetch-secret
kubectl apply -f fetch-secret-job.yaml
kubectl -n swa-probe logs job/fetch-secret -f
```

## Rename note
`fetch-secret-main.go` and `fetch-secret-go.mod` are named that way so they
don't collide with the existing `swa-probe` files in this delivery. When you
copy them into their own project directory, rename them back to `main.go`
and `go.mod`.
