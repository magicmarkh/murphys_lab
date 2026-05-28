#!/usr/bin/env bash
# =============================================================================
# load-policy.sh
# =============================================================================
# Loads Conjur policies in dependency order.
#
# Uses "policy update" (additive) by default so it won't delete existing
# resources. Use --replace for full replace (destructive).
#
# Requires the Conjur CLI to be installed, configured, and authenticated.
#
# Usage:
#   CONJURRC=~/.conjurrc ./load-policy.sh             # additive update (safe)
#   CONJURRC=~/.conjurrc ./load-policy.sh --replace    # full replace (destructive)
#   CONJURRC=~/.conjurrc ./load-policy.sh --dry-run    # print actions, do not execute
# =============================================================================

set -euo pipefail

MODE="update"
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --replace) MODE="load"   ;;
    --dry-run) DRY_RUN=1     ;;
    -h|--help)
      sed -n '1,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

run() {
  local branch="$1"
  local file="$2"
  echo ">> conjur policy $MODE -b $branch -f $file"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    conjur policy "$MODE" -b "$branch" -f "$file"
  fi
}

echo "=========================================="
echo "Loading Conjur policies (mode: $MODE)"
echo "=========================================="

# 1. Data hosts + annotation + vault grants (data branch)
run data data/hosts.yml

# 2. Cross-branch grants: connect data hosts to authenticator groups (root branch)
run root grants.yml

echo ""
echo "All policies processed."
