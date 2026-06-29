#!/usr/bin/env bash
# Quick sanity checks against a running SWA demo deployment.
# Run from a laptop with kubectl pointed at the Kind cluster.
set -euo pipefail

NS="${NS:-swa-demo}"

echo "==> SWA Agent pods"
kubectl -n cyberark-swa get pods -o wide

echo
echo "==> Demo pods"
kubectl -n "${NS}" get pods -o wide

echo
echo "==> secret-fetcher logs (JWT-SVID demo, last 30 lines)"
kubectl -n "${NS}" logs deploy/secret-fetcher --tail=30 || true

echo
echo "==> Workload API socket mounted by the CSI driver into mtls-server"
kubectl -n "${NS}" exec deploy/mtls-server -c svid-writer -- ls -l /spiffe-workload-api || true

echo
echo "==> SVID files written by the svid-writer sidecar"
kubectl -n "${NS}" exec deploy/mtls-server -c listener -- ls -l /var/run/svids || true

echo
echo "==> mtls-client (dialer) logs (X.509-SVID demo, last 30 lines)"
kubectl -n "${NS}" logs deploy/mtls-client -c dialer --tail=30 || true
