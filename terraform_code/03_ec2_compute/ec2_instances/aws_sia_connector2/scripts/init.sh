#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

FLAG=/var/log/sia_init_done
LOG=/var/log/sia_init.log

if (( EUID != 0 )); then
  echo "[init] Must run as root" >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 NEW_HOSTNAME" >&2
  exit 1
fi

NEW_HOST="$1"

if [[ -f "$FLAG" ]]; then
  echo "[init] Already initialized; exiting." | tee -a "$LOG"
  exit 0
fi

{
  date && echo "[init] Setting hostname → $NEW_HOST"
  hostnamectl set-hostname "$NEW_HOST"

  # update /etc/hosts
  if grep -q '^127\.0\.1\.1' /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $NEW_HOST/" /etc/hosts
  else
    echo "127.0.1.1 $NEW_HOST" >> /etc/hosts
  fi

  echo "[init] Hostname and /etc/hosts updated."
  echo "[init] Init complete."
} 2>&1 | tee -a "$LOG"

touch "$FLAG"
