# syntax=docker/dockerfile:1

# ---- Stage 1: build a static binary --------------------------------------
FROM golang:1.22-alpine AS build
WORKDIR /src

# Cache modules first (this app is stdlib-only, so this is just go.mod).
COPY go.mod ./
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

# NOTE: This image uses the HTTP-over-UDS method (SWA_METHOD=http|auto), which
# needs NO extra binary in the container. If you instead want SWA_METHOD=cli,
# the swa-agent binary must exist in the container at $SWA_AGENT_BIN — either
# hostPath-mount it from the node (see k8s.yaml) or COPY it into this stage.
# distroless has no shell, so `cli` still works via direct exec (no shell needed).
