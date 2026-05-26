#!/usr/bin/env bash
# =============================================================================
# load-policy.sh
# =============================================================================
# Loads every policy file in this repo into Conjur Cloud in dependency order:
#
#   1. data/data.yml                    -> data
#   2. data/{terraform,static,dynamic,swa}.yml
#                                       -> data
#   3. data/vault/vault.yml             -> data
#   4. data/vault/<safe>.yml            -> data/vault
#
# Requires the Conjur CLI (`conjur`) to be installed, configured, and
# authenticated against the target tenant.
#
# Usage:
#   ./load-policy.sh             # full replace ("policy load")
#   ./load-policy.sh --update    # additive ("policy update")
#   ./load-policy.sh --dry-run   # print actions, do not execute
# =============================================================================

set -euo pipefail

MODE="load"
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --update)  MODE="update"  ;;
    --dry-run) DRY_RUN=1      ;;
    -h|--help)
      sed -n '1,30p' "$0"
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

# -----------------------------------------------------------------------------
# 1. data - admin groups, loose hosts, sub-policy stubs
# -----------------------------------------------------------------------------
run data data/data.yml

# -----------------------------------------------------------------------------
# 2. data/* - terraform, static, dynamic, swa
# -----------------------------------------------------------------------------
run data data/terraform.yml
run data data/static.yml
run data data/dynamic.yml
run data data/swa.yml

# -----------------------------------------------------------------------------
# 3. data/vault - per-safe admin groups + sub-policy stubs
# -----------------------------------------------------------------------------
run data data/vault/vault.yml

# -----------------------------------------------------------------------------
# 4. data/vault/<safe> - per-safe accounts, variables, delegation
# -----------------------------------------------------------------------------
run data/vault data/vault/m-aws-keys.yml
run data/vault data/vault/m-aws-pem-unmanaged.yml
run data/vault data/vault/m-conjur-automation.yml
run data/vault data/vault/m-priv-svc-accts.yml
run data/vault data/vault/Trevor-AWS-Test.yml

echo "All policies processed."
