# swa-probe — CyberArk Secure Workload Access connectivity test

A tiny, dependency-free app that proves a Kubernetes workload can obtain a
**JWT-SVID** from the node-local **SWA Agent** over a mounted Unix Domain
Socket. Use it to validate attestation + agent wiring before you point a real
service at Conjur / Secrets Manager.

## Files
- `main.go` — Go probe (stdlib only → static binary, fits scratch/distroless)
- `app.py` — Python equivalent (stdlib only)
- `Dockerfile` — multi-stage build → `distroless/static:nonroot`
- `k8s.yaml` — Namespace + ServiceAccount + Deployment with hostPath socket mount

## How it works
1. Waits for the Agent socket to appear at `SWA_SOCKET_PATH`.
2. Requests a JWT-SVID for `SWA_AUDIENCE` (default `conjur`) via one of:
   - `http` — POST over the UDS (no extra binary; works in a minimal image)
   - `cli` — exec `swa-agent api fetch jwt --audience <aud> --socketPath <sock>`
   - `auto` — try `http`, then fall back to `cli`
3. Decodes the JWT payload (unverified, display only) and prints `sub`
   (your SPIFFE ID), `aud`, `iss`, `exp`. Exit 0 on success.

## Build & run
```bash
docker build -t your-registry.example.com/swa-probe:0.1.0 .
docker push  your-registry.example.com/swa-probe:0.1.0
# edit the image ref in k8s.yaml, then:
kubectl apply -f k8s.yaml
kubectl -n swa-probe logs deploy/swa-probe
```
Success looks like:
```
[swa-probe] SUCCESS: fetched a JWT-SVID via "http-over-uds" (…)
[swa-probe]   sub (SPIFFE ID) : spiffe://<trust-domain>/k8s-nodegroup/ns/swa-probe/sa/swa-probe
[swa-probe]   aud             : conjur
```

## Config (env vars)
| var | default | notes |
|---|---|---|
| `SWA_SOCKET_PATH` | `/run/swa-agent/api.sock` | must match the hostPath + agent config |
| `SWA_AUDIENCE` | `conjur` | audience for the JWT-SVID |
| `SWA_METHOD` | `auto` | `auto` \| `http` \| `cli` |
| `SWA_AGENT_BIN` | `/opt/swa/bin/swa-agent` | only used by `cli` |
| `SWA_HTTP_PATH` | `/svid/jwt` | agent-specific; adjust to your API |
| `SWA_WAIT_TIMEOUT` | `30s` | how long to wait for the socket |
| `SWA_PRINT_TOKEN` | `false` | `true` prints the raw token (debug only) |

## Recommended for production: the SPIFFE Workload API
This probe talks plain HTTP/CLI to stay zero-dependency, but the SWA/SPIFFE
Workload API is **gRPC over the UDS**. A stock agent may not expose a REST
endpoint at all — in that case use `cli`, or (better) use the SPIFFE client,
which is the portable, rotation-aware, correct way:

```go
import (
    "context"
    "github.com/spiffe/go-spiffe/v2/workloadapi"
    "github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
)

func fetchJWTSVID(ctx context.Context) (*jwtsvid.SVID, error) {
    return workloadapi.FetchJWTSVID(ctx,
        jwtsvid.Params{Audience: "conjur"},
        workloadapi.WithClientOptions(
            workloadapi.WithAddr("unix:///run/swa-agent/api.sock"),
        ),
    )
}
```
Python equivalent: the `spiffe` package (`default_jwt_source` /
`fetch_jwt_svid`). For long-running services, keep a `JWTSource`/`X509Source`
open so the library serves fresh SVIDs as the agent rotates them — don't fetch
once and cache the token.

## From probe to Conjur
The JWT-SVID's `sub` is your SPIFFE ID. In Secrets Manager you configure a JWT
authenticator whose `token-app-property`/`identity-path` map that `sub` to a
Conjur workload, then grant that workload read on the secrets it needs. Your
real app: fetch JWT-SVID → authenticate to the authenticator → use the returned
access token to read secrets via the Secrets Manager REST API.

## Security notes
- **Don't log tokens.** `SWA_PRINT_TOKEN` defaults to `false`; keep it off
  outside debugging. JWT-SVIDs are short-lived bearer credentials.
- **Unverified decode.** The `sub/aud/exp` print is base64 decode only, for a
  human sanity check. Never make authz decisions on unverified claims — the
  relying party (Conjur) verifies the signature against the SWA JWKS.
- **Least-privilege pod.** Runs nonroot, read-only root FS, all caps dropped,
  socket mounted read-only. See the socket-permission gotcha in `k8s.yaml`.
- **hostPath scope.** Mount only the agent socket directory, never a broader
  host path. On PSA-restricted clusters, place this in a namespace whose policy
  permits the hostPath mount, or use the agent's CSI driver if one is provided.
