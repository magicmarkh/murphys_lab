# syntax=docker/dockerfile:1

# ---- Stage 1: build a static binary --------------------------------------
FROM golang:1.22-alpine AS build
WORKDIR /src

# Cache modules first. This app now depends on github.com/spiffe/go-spiffe/v2
# (real SPIFFE Workload API client, gRPC-over-UDS) instead of the earlier
# dependency-free HTTP/CLI guesswork, so go.sum is required — generate it
# once with `go mod tidy` in an environment with normal network access
# (proxy.golang.org reachable), then commit both go.mod and go.sum.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# CGO_ENABLED=0 -> fully static binary that runs on scratch/distroless-static.
# -trimpath and -ldflags strip paths/symbols for a smaller, cleaner artifact.
RUN CGO_ENABLED=0 GOOS=linux go build \
      -trimpath -ldflags="-s -w" \
      -o /out/swa-probe .

# ---- Stage 2: minimal runtime image --------------------------------------
# distroless/static:nonroot has no shell, no package manager, a non-root user
# (uid 65532), and CA certs. Smallest safe base for a static Go binary.
FROM gcr.io/distroless/static:nonroot

COPY --from=build /out/swa-probe /usr/local/bin/swa-probe

# Runs as uid:gid 65532:65532 (nonroot) by default from the base image.
ENTRYPOINT ["/usr/local/bin/swa-probe"]

# NOTE: This probe now talks the real SPIFFE Workload API (gRPC-over-UDS) via
# go-spiffe, matching what this environment's SWA Agent (SPIRE-based) actually
# exposes. No vendor CLI binary or hostPath binary mount is needed anymore —
# SWA_AGENT_BIN / SWA_METHOD / SWA_HTTP_PATH env vars from earlier revisions
# are gone; see README for the current SWA_SOCKET_PATH / SWA_AUDIENCE vars.