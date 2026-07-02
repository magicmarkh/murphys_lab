# syntax=docker/dockerfile:1

# ---- Stage 1: build a static binary --------------------------------------
FROM golang:1.22-alpine AS build
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
      -trimpath -ldflags="-s -w" \
      -o /out/fetch-secret .

# ---- Stage 2: minimal runtime image --------------------------------------
FROM gcr.io/distroless/static:nonroot

COPY --from=build /out/fetch-secret /usr/local/bin/fetch-secret

ENTRYPOINT ["/usr/local/bin/fetch-secret"]

# This is a DEMO tool: it deliberately prints secret values to stdout so a
# person watching a live demo can see the round trip worked. Don't reuse this
# pattern for anything that isn't a live demo.
