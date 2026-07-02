#!/usr/bin/env python3
"""Lightweight CyberArk Secure Workload Access (SWA) connectivity probe.

Standard-library only. Fetches a JWT-SVID from the node-local SWA Agent over a
mounted Unix Domain Socket and prints a confirmation. Mirrors main.go.

Env vars:
  SWA_SOCKET_PATH  (default /run/swa-agent/api.sock)
  SWA_AUDIENCE     (default conjur)
  SWA_METHOD       auto | http | cli   (default auto)
  SWA_AGENT_BIN    (default /opt/swa/bin/swa-agent)
  SWA_HTTP_PATH    (default /svid/jwt)  agent-specific
  SWA_WAIT_TIMEOUT seconds (default 30)
  SWA_PRINT_TOKEN  true|false (default false)

Production tip: prefer the SPIFFE Workload API via the `spiffe` PyPI package
(spiffe.workloadapi.default_jwt_source / fetch_jwt_svid) which speaks the real
gRPC-over-UDS protocol and handles rotation. This probe stays dependency-free.
"""
import base64
import http.client
import json
import os
import re
import socket
import subprocess
import sys
import time

JWT_RE = re.compile(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+")


def env(k, default):
    v = os.environ.get(k)
    return v if v else default


def log(msg):
    print(f"[swa-probe] {msg}", file=sys.stderr)


class UDSConnection(http.client.HTTPConnection):
    """HTTPConnection that dials a Unix Domain Socket instead of TCP."""

    def __init__(self, socket_path, timeout=10):
        super().__init__("localhost", timeout=timeout)
        self._socket_path = socket_path

    def connect(self):
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(self.timeout)
        sock.connect(self._socket_path)
        self.sock = sock


def wait_for_socket(path, timeout):
    deadline = time.time() + timeout
    while True:
        if os.path.exists(path):
            import stat
            if stat.S_ISSOCK(os.stat(path).st_mode):
                return
            raise RuntimeError(f"{path} exists but is not a socket")
        if time.time() > deadline:
            raise TimeoutError(f"timed out waiting for {path}")
        time.sleep(0.5)


def extract_token(raw):
    s = raw.strip()
    if not s:
        raise ValueError("empty response from agent")
    try:
        obj = json.loads(s)
        if isinstance(obj, dict):
            for k in ("token", "jwt", "svid", "jwt_svid", "jwtSvid"):
                if isinstance(obj.get(k), str) and obj[k]:
                    return obj[k]
    except json.JSONDecodeError:
        pass
    m = JWT_RE.search(s)
    if m:
        return m.group(0)
    raise ValueError(f"no JWT found in agent output: {s[:120]}")


def fetch_via_http(socket_path, http_path, audience):
    conn = UDSConnection(socket_path)
    body = json.dumps({"audience": audience, "audiences": [audience]})
    headers = {"Content-Type": "application/json", "Workload.Spiffe.Io": "true"}
    conn.request("POST", http_path, body=body, headers=headers)
    resp = conn.getresponse()
    data = resp.read().decode("utf-8", "replace")
    conn.close()
    if not (200 <= resp.status < 300):
        raise RuntimeError(f"agent returned HTTP {resp.status}: {data[:200]}")
    return extract_token(data)


def fetch_via_cli(agent_bin, audience, socket_path):
    if not os.path.exists(agent_bin):
        raise FileNotFoundError(f"agent binary not found at {agent_bin}")
    out = subprocess.run(
        [agent_bin, "api", "fetch", "jwt",
         "--audience", audience, "--socketPath", socket_path],
        capture_output=True, text=True, timeout=15, check=True,
    )
    return extract_token(out.stdout + out.stderr)


def decode_claims(token):
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("not a 3-part JWT")
    payload = parts[1] + "=" * (-len(parts[1]) % 4)  # pad base64url
    return json.loads(base64.urlsafe_b64decode(payload))


def main():
    socket_path = env("SWA_SOCKET_PATH", "/run/swa-agent/api.sock")
    audience = env("SWA_AUDIENCE", "conjur")
    method = env("SWA_METHOD", "auto").lower()
    agent_bin = env("SWA_AGENT_BIN", "/opt/swa/bin/swa-agent")
    http_path = env("SWA_HTTP_PATH", "/svid/jwt")
    timeout = float(env("SWA_WAIT_TIMEOUT", "30"))
    print_token = env("SWA_PRINT_TOKEN", "false").lower() == "true"

    log(f"starting swa-probe | socket={socket_path} audience={audience!r} method={method}")
    wait_for_socket(socket_path, timeout)
    log(f"socket is present: {socket_path}")

    errors = []
    token = via = None
    if method in ("http", "auto"):
        try:
            token, via = fetch_via_http(socket_path, http_path, audience), "http-over-uds"
        except Exception as e:  # noqa: BLE001
            errors.append(f"http: {e}")
    if token is None and method in ("cli", "auto"):
        try:
            token, via = fetch_via_cli(agent_bin, audience, socket_path), "cli"
        except Exception as e:  # noqa: BLE001
            errors.append(f"cli: {e}")

    if token is None:
        log("FATAL: failed to fetch JWT-SVID: " + "; ".join(errors))
        sys.exit(1)

    log(f"SUCCESS: fetched a JWT-SVID via {via!r} ({len(token)} bytes)")
    try:
        c = decode_claims(token)
        log(f"  sub (SPIFFE ID) : {c.get('sub', '<none>')}")
        log(f"  aud             : {c.get('aud', '<none>')}")
        log(f"  iss             : {c.get('iss', '<none>')}")
        log(f"  exp             : {c.get('exp', '<none>')}")
    except Exception as e:  # noqa: BLE001
        log(f"note: could not decode claims: {e}")

    if print_token:
        print(token)
    else:
        log("token retrieved (set SWA_PRINT_TOKEN=true to print the raw token)")


if __name__ == "__main__":
    main()
