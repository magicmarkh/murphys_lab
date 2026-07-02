// Command swa-probe is a lightweight connectivity test for CyberArk
// Secure Workload Access (SWA). It runs inside a Kubernetes pod, talks to the
// node-local SWA Agent over a mounted Unix Domain Socket, requests a JWT-SVID
// for a given audience (default "conjur"), and prints a confirmation so you can
// verify that workload identity is wired up end to end.
//
// It deliberately uses ONLY the Go standard library so it builds anywhere and
// compiles to a tiny static binary that fits in a scratch/distroless image.
//
// Two fetch methods are supported (see SWA_METHOD):
//
//	http : POST to the Agent's local API over the UDS (no extra binary needed;
//	       works in a minimal image). The request path/shape is agent-specific,
//	       so it is configurable via SWA_HTTP_PATH.
//	cli  : exec the local swa-agent binary exactly as documented:
//	         swa-agent api fetch jwt --audience <aud> --socketPath <sock>
//	       This requires the swa-agent binary to be present in the container
//	       (bake it in or hostPath-mount it) and a base image that can exec it.
//
// For production code, prefer the SPIFFE Workload API via github.com/spiffe/
// go-spiffe/v2 (workloadapi.FetchJWTSVID). See README.md — that client speaks
// the real gRPC-over-UDS Workload API and handles rotation. This probe stays
// dependency-free on purpose.
package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"regexp"
	"strings"
	"syscall"
	"time"
)

type config struct {
	socketPath  string
	audience    string
	method      string // "auto" | "http" | "cli"
	agentBin    string
	httpPath    string
	waitTimeout time.Duration
	printToken  bool
}

func loadConfig() config {
	return config{
		socketPath:  env("SWA_SOCKET_PATH", "/run/swa-agent/api.sock"),
		audience:    env("SWA_AUDIENCE", "conjur"),
		method:      strings.ToLower(env("SWA_METHOD", "auto")),
		agentBin:    env("SWA_AGENT_BIN", "/opt/swa/bin/swa-agent"),
		httpPath:    env("SWA_HTTP_PATH", "/svid/jwt"),
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

	logf("starting swa-probe | socket=%s audience=%q method=%s", cfg.socketPath, cfg.audience, cfg.method)

	// Wait for the Agent socket to appear. In Kubernetes the DaemonSet agent and
	// this pod start independently, so the socket may not exist for a moment.
	if err := waitForSocket(ctx, cfg.socketPath, cfg.waitTimeout); err != nil {
		fatal("socket not ready: %v", err)
	}
	logf("socket is present: %s", cfg.socketPath)

	token, via, err := fetchJWT(ctx, cfg)
	if err != nil {
		fatal("failed to fetch JWT-SVID: %v", err)
	}

	claims, cerr := decodeJWTClaims(token)
	logf("SUCCESS: fetched a JWT-SVID via %q (%d bytes)", via, len(token))
	if cerr != nil {
		logf("note: could not decode claims for display: %v", cerr)
	} else {
		logf("  sub (SPIFFE ID) : %s", str(claims["sub"]))
		logf("  aud             : %s", audString(claims["aud"]))
		logf("  iss             : %s", str(claims["iss"]))
		logf("  exp             : %s", unixTime(claims["exp"]))
	}

	if cfg.printToken {
		fmt.Println(token) // opt-in: tokens are secrets; avoid logging them by default.
	} else {
		logf("token retrieved (set SWA_PRINT_TOKEN=true to print the raw token)")
	}
}

// fetchJWT dispatches to the configured method, falling back http->cli in auto mode.
func fetchJWT(ctx context.Context, cfg config) (token, via string, err error) {
	switch cfg.method {
	case "http":
		token, err = fetchViaHTTP(ctx, cfg)
		return token, "http-over-uds", err
	case "cli":
		token, err = fetchViaCLI(ctx, cfg)
		return token, "cli", err
	case "auto":
		token, err = fetchViaHTTP(ctx, cfg)
		if err == nil {
			return token, "http-over-uds", nil
		}
		logf("http method failed (%v); trying cli", err)
		token, cerr := fetchViaCLI(ctx, cfg)
		if cerr == nil {
			return token, "cli", nil
		}
		return "", "", fmt.Errorf("http error: %v; cli error: %v", err, cerr)
	default:
		return "", "", fmt.Errorf("unknown SWA_METHOD %q (want auto|http|cli)", cfg.method)
	}
}

// fetchViaHTTP POSTs to the Agent's local API over the Unix Domain Socket.
func fetchViaHTTP(ctx context.Context, cfg config) (string, error) {
	transport := &http.Transport{
		DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
			var d net.Dialer
			return d.DialContext(ctx, "unix", cfg.socketPath)
		},
	}
	client := &http.Client{Transport: transport, Timeout: 10 * time.Second}

	body, _ := json.Marshal(map[string]any{
		"audience":  cfg.audience,
		"audiences": []string{cfg.audience},
	})
	// The host in the URL is ignored for a UDS dial; a placeholder keeps it valid.
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "http://swa-agent"+cfg.httpPath, bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	// SPIFFE Workload API convention; harmless if the agent ignores it.
	req.Header.Set("Workload.Spiffe.Io", "true")

	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	buf := new(bytes.Buffer)
	if _, err := buf.ReadFrom(resp.Body); err != nil {
		return "", err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("agent returned HTTP %d: %s", resp.StatusCode, truncate(buf.String(), 200))
	}
	return extractToken(buf.Bytes())
}

// fetchViaCLI execs the local swa-agent binary as documented.
func fetchViaCLI(ctx context.Context, cfg config) (string, error) {
	if _, err := os.Stat(cfg.agentBin); err != nil {
		return "", fmt.Errorf("agent binary not found at %s (bake it in or hostPath-mount it): %w", cfg.agentBin, err)
	}
	cctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()

	cmd := exec.CommandContext(cctx, cfg.agentBin,
		"api", "fetch", "jwt",
		"--audience", cfg.audience,
		"--socketPath", cfg.socketPath,
	)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("%s: %w: %s", cfg.agentBin, err, truncate(string(out), 200))
	}
	return extractToken(out)
}

var jwtPattern = regexp.MustCompile(`eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+`)

// extractToken pulls a JWT out of raw agent output. It accepts a bare token, a
// JSON object with a common token field, or arbitrary text containing a JWT.
func extractToken(raw []byte) (string, error) {
	s := strings.TrimSpace(string(raw))
	if s == "" {
		return "", errors.New("empty response from agent")
	}
	// Try JSON with a few common field names.
	var obj map[string]json.RawMessage
	if json.Unmarshal([]byte(s), &obj) == nil {
		for _, k := range []string{"token", "jwt", "svid", "jwt_svid", "jwtSvid"} {
			if v, ok := obj[k]; ok {
				var str string
				if json.Unmarshal(v, &str) == nil && str != "" {
					return str, nil
				}
			}
		}
	}
	// Bare token or token embedded in text.
	if m := jwtPattern.FindString(s); m != "" {
		return m, nil
	}
	return "", fmt.Errorf("no JWT found in agent output: %s", truncate(s, 120))
}

// decodeJWTClaims base64-decodes the JWT payload WITHOUT verifying the signature.
// This is only for human-readable confirmation of a connectivity test. Never
// trust unverified claims for authorization decisions.
func decodeJWTClaims(token string) (map[string]any, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return nil, fmt.Errorf("not a 3-part JWT")
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, err
	}
	var claims map[string]any
	if err := json.Unmarshal(payload, &claims); err != nil {
		return nil, err
	}
	return claims, nil
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

// ---- small display helpers ----

func str(v any) string {
	if v == nil {
		return "<none>"
	}
	return fmt.Sprintf("%v", v)
}

func audString(v any) string {
	switch t := v.(type) {
	case nil:
		return "<none>"
	case string:
		return t
	case []any:
		parts := make([]string, 0, len(t))
		for _, e := range t {
			parts = append(parts, fmt.Sprintf("%v", e))
		}
		return strings.Join(parts, ", ")
	default:
		return fmt.Sprintf("%v", v)
	}
}

func unixTime(v any) string {
	f, ok := v.(float64)
	if !ok {
		return str(v)
	}
	t := time.Unix(int64(f), 0).UTC()
	return fmt.Sprintf("%s (in %s)", t.Format(time.RFC3339), time.Until(t).Truncate(time.Second))
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "…"
}

func logf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "[swa-probe] "+format+"\n", args...)
}

func fatal(format string, args ...any) {
	logf("FATAL: "+format, args...)
	os.Exit(1)
}
