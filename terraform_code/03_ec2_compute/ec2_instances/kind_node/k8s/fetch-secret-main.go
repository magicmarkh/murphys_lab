// Command fetch-secret is a demo tool that shows the full SWA -> Secrets
// Manager SaaS flow end to end:
//
//  1. Fetch a JWT-SVID from the node-local SWA Agent (SPIFFE Workload API,
//     gRPC-over-UDS) — same mechanism as swa-probe.
//  2. Exchange that JWT-SVID for a short-lived Secrets Manager access token
//     via the JWT authenticator REST API.
//  3. Use the access token to retrieve one or more secrets (e.g. a
//     username/password pair) via the Secrets Manager REST API, and print
//     them to stdout for a live demo.
//
// This intentionally prints secret values in plain text — it's a demo tool
// to show a person watching that the round trip actually works, not a
// production credential handler. Don't wire this into anything real.
//
// Endpoints per CyberArk Secrets Manager SaaS docs:
//   - JWT authenticator: POST /api/authn-jwt/{service-id}/conjur/authenticate
//     https://docs.cyberark.com/secrets-manager-saas/latest/en/content/developer/conjur_api_jwt_authenticator.htm
//   - Retrieve a secret:  GET  /api/secrets/conjur/variable/{identifier}
//     https://docs.cyberark.com/secrets-manager-saas/latest/en/content/developer/conjur_api_retrieve_secret.htm
package main

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

type config struct {
	socketPath  string // SPIFFE Workload API UDS
	audience    string // JWT-SVID audience (must match what Secrets Manager expects)
	waitTimeout time.Duration

	subdomain string // e.g. "murphyslab" -> https://murphyslab.secretsmgr.cyberark.cloud
	serviceID string // the authn-jwt service ID, e.g. "spiffe-auth" (no "authn-jwt/" prefix)

	usernameVar string // Conjur variable identifier for the username, e.g. "data/demo/db/username" (optional)
	passwordVar string // Conjur variable identifier for the password/secret, e.g. "data/demo/db/password" (required)
}

func loadConfig() (config, error) {
	c := config{
		socketPath:  env("SWA_SOCKET_PATH", "/tmp/swa-agent/public/api.sock"),
		audience:    env("SWA_AUDIENCE", "conjur"),
		waitTimeout: envDuration("SWA_WAIT_TIMEOUT", 30*time.Second),
		subdomain:   env("SECRETS_MGR_SUBDOMAIN", ""),
		serviceID:   env("SECRETS_MGR_JWT_SERVICE_ID", ""),
		usernameVar: env("SECRETS_MGR_USERNAME_VAR", ""),
		passwordVar: env("SECRETS_MGR_PASSWORD_VAR", ""),
	}
	var missing []string
	if c.subdomain == "" {
		missing = append(missing, "SECRETS_MGR_SUBDOMAIN")
	}
	if c.serviceID == "" {
		missing = append(missing, "SECRETS_MGR_JWT_SERVICE_ID")
	}
	if c.passwordVar == "" {
		missing = append(missing, "SECRETS_MGR_PASSWORD_VAR")
	}
	if len(missing) > 0 {
		return c, fmt.Errorf("missing required env var(s): %s", strings.Join(missing, ", "))
	}
	return c, nil
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
	cfg, err := loadConfig()
	if err != nil {
		fatal("%v", err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	baseURL := fmt.Sprintf("https://%s.secretsmgr.cyberark.cloud", cfg.subdomain)

	// --- Step 1: fetch a JWT-SVID from the SWA Agent -----------------------
	logf("step 1/3: fetching JWT-SVID from SWA Agent | socket=%s audience=%q", cfg.socketPath, cfg.audience)
	if err := waitForSocket(ctx, cfg.socketPath, cfg.waitTimeout); err != nil {
		fatal("socket not ready: %v", err)
	}

	fetchCtx, cancel := context.WithTimeout(ctx, 15*time.Second)
	svid, err := workloadapi.FetchJWTSVID(fetchCtx,
		jwtsvid.Params{Audience: cfg.audience},
		workloadapi.WithAddr("unix://"+cfg.socketPath),
	)
	cancel()
	if err != nil {
		fatal("failed to fetch JWT-SVID: %v", err)
	}
	logf("  got JWT-SVID for sub=%s (%d bytes)", svid.ID.String(), len(svid.Marshal()))

	// --- Step 2: exchange the JWT-SVID for a Secrets Manager access token --
	logf("step 2/3: authenticating to Secrets Manager | tenant=%s service-id=%s", cfg.subdomain, cfg.serviceID)
	accessToken, err := authenticate(ctx, baseURL, cfg.serviceID, svid.Marshal())
	if err != nil {
		fatal("failed to authenticate to Secrets Manager: %v", err)
	}
	logf("  authenticated; received short-lived access token (%d bytes)", len(accessToken))

	// --- Step 3: retrieve the secret(s) and print them ----------------------
	logf("step 3/3: retrieving secret(s) from Secrets Manager")

	var username string
	if cfg.usernameVar != "" {
		username, err = retrieveSecret(ctx, baseURL, accessToken, cfg.usernameVar)
		if err != nil {
			fatal("failed to retrieve username variable %q: %v", cfg.usernameVar, err)
		}
	}

	password, err := retrieveSecret(ctx, baseURL, accessToken, cfg.passwordVar)
	if err != nil {
		fatal("failed to retrieve password/secret variable %q: %v", cfg.passwordVar, err)
	}

	fmt.Println()
	fmt.Println("========================================")
	fmt.Println(" Secret retrieved from Secrets Manager SaaS")
	fmt.Println("========================================")
	fmt.Printf(" Workload (SPIFFE ID): %s\n", svid.ID.String())
	if cfg.usernameVar != "" {
		fmt.Printf(" Username : %s\n", username)
	}
	fmt.Printf(" Secret   : %s\n", password)
	fmt.Println("========================================")
}

// authenticate exchanges a JWT-SVID for a Secrets Manager access token via
// the JWT authenticator REST API. Uses the token-app-property flow (no
// host-id in the URL) — the authenticator maps the JWT's `sub` claim to a
// workload automatically.
func authenticate(ctx context.Context, baseURL, serviceID, jwt string) (string, error) {
	endpoint := fmt.Sprintf("%s/api/authn-jwt/%s/conjur/authenticate", baseURL, url.PathEscape(serviceID))

	form := url.Values{}
	form.Set("jwt", jwt)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, strings.NewReader(form.Encode()))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	// Accept-Encoding: base64 -> response body is a ready-to-use base64
	// access token (see docs). Without this header the body is raw JSON
	// and needs different handling.
	req.Header.Set("Accept-Encoding", "base64")

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("HTTP %d: %s", resp.StatusCode, truncate(string(body), 300))
	}
	return strings.TrimSpace(string(body)), nil
}

// retrieveSecret fetches a single secret value via the Secrets Manager REST
// API using the access token obtained from authenticate().
func retrieveSecret(ctx context.Context, baseURL, accessToken, identifier string) (string, error) {
	// Path segments (e.g. "data/db/password") must be URL-encoded as a
	// single unit — slashes become %2F, per the docs' examples.
	encodedID := url.QueryEscape(identifier)
	endpoint := fmt.Sprintf("%s/api/secrets/conjur/variable/%s", baseURL, encodedID)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Authorization", fmt.Sprintf(`Token token="%s"`, accessToken))

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("HTTP %d: %s", resp.StatusCode, truncate(string(body), 300))
	}
	return string(body), nil
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

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "…"
}

func logf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "[fetch-secret] "+format+"\n", args...)
}

func fatal(format string, args ...any) {
	logf("FATAL: "+format, args...)
	os.Exit(1)
}
