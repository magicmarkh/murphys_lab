// Command swa-probe is a lightweight connectivity test for CyberArk
// Secure Workload Access (SWA). It runs inside a Kubernetes pod, talks to the
// node-local SWA Agent over the SPIFFE Workload API (gRPC over a mounted Unix
// Domain Socket), requests a JWT-SVID for a given audience (default
// "conjur"), and prints a confirmation so you can verify that workload
// identity is wired up end to end.
//
// This uses the official github.com/spiffe/go-spiffe/v2 client, which speaks
// the real Workload API protocol (gRPC-over-UDS) and is the portable,
// rotation-aware way to fetch SVIDs. Earlier revisions of this probe tried a
// hand-rolled HTTP-over-UDS call and a `swa-agent` CLI exec as a
// dependency-free stopgap; against this deployment's SWA Agent (a
// SPIRE-based agent exposing only the real Workload API — no REST listener),
// only the Workload API path works, so that guesswork has been removed.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

type config struct {
	socketPath  string // filesystem path to the Workload API UDS
	audience    string
	waitTimeout time.Duration
	printToken  bool
}

func loadConfig() config {
	return config{
		// NOTE: this deployment's SWA Agent binds its socket at
		// /tmp/swa-agent/public/api.sock (hostPath: /tmp/swa-agent, agent
		// writes into a "public" subdirectory). Confirmed via:
		//   docker exec <kind-node> ls -la /tmp/swa-agent/public
		socketPath:  env("SWA_SOCKET_PATH", "/tmp/swa-agent/public/api.sock"),
		audience:    env("SWA_AUDIENCE", "conjur"),
		waitTimeout: envDuration("SWA_WAIT_TIMEOUT", 30*time.Second),
		printToken:  strings.EqualFold(env("SWA_PRINT_TOKEN", "false"), "true"),
	}
}

func env(k, def string) string {
	if v, ok := os.LookupEnv(k); ok && v != "" {
		return v
	}
	return def
}

func envDuration(k string, def time.Duration) time.Duration {
	if v, ok := os.LookupEnv(k); ok && v != "" {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return def
}

func main() {
	cfg := loadConfig()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	logf("starting swa-probe | socket=%s audience=%q method=workload-api", cfg.socketPath, cfg.audience)

	if err := waitForSocket(ctx, cfg.socketPath, cfg.waitTimeout); err != nil {
		fatal("socket not ready: %v", err)
	}
	logf("socket is present: %s", cfg.socketPath)

	fetchCtx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()

	// The real deal: gRPC-over-UDS via the SPIFFE Workload API. No REST
	// guessing, no CLI exec, no vendored binary — this is what a production
	// client (Go or otherwise) should actually do, and it's rotation-aware
	// if you keep a long-lived JWTSource open (see README) instead of a
	// one-shot fetch like this probe does.
	svid, err := workloadapi.FetchJWTSVID(fetchCtx,
		jwtsvid.Params{Audience: cfg.audience},
		workloadapi.WithAddr("unix://"+cfg.socketPath),
	)
	if err != nil {
		fatal("failed to fetch JWT-SVID: %v", err)
	}

	token := svid.Marshal()
	logf("SUCCESS: fetched a JWT-SVID via %q (%d bytes)", "workload-api", len(token))
	logf("  sub (SPIFFE ID) : %s", svid.ID.String())
	logf("  aud             : %s", strings.Join(svid.Audience, ", "))
	logf("  exp             : %s (in %s)", svid.Expiry.UTC().Format(time.RFC3339), time.Until(svid.Expiry).Truncate(time.Second))
	if iss, ok := svid.Claims["iss"]; ok {
		logf("  iss             : %s", jsonStr(iss))
	}

	if cfg.printToken {
		fmt.Println(token) // opt-in: tokens are secrets; avoid logging them by default.
	} else {
		logf("token retrieved (set SWA_PRINT_TOKEN=true to print the raw token)")
	}
}

func jsonStr(v any) string {
	if s, ok := v.(string); ok {
		return s
	}
	b, err := json.Marshal(v)
	if err != nil {
		return fmt.Sprintf("%v", v)
	}
	return string(b)
}

func waitForSocket(ctx context.Context, path string, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	for {
		if fi, err := os.Stat(path); err == nil {
			if fi.Mode()&os.ModeSocket != 0 {
				return nil
			}
			return fmt.Errorf("%s exists but is not a socket", path)
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("timed out after %s waiting for %s", timeout, path)
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(500 * time.Millisecond):
		}
	}
}

func logf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "[swa-probe] "+format+"\n", args...)
}

func fatal(format string, args ...any) {
	logf("FATAL: "+format, args...)
	os.Exit(1)
}