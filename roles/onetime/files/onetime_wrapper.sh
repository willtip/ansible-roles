#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# onetime_wrapper.sh
# Generic wrapper dropped onto the target by the onetime role.
#
# Usage:
#   ./onetime_wrapper.sh <migration_script> [args…]
#
# What it does:
#   1. Logs start/end with timestamps
#   2. Invokes the provided migration script
#   3. Exits with the script's exit code so Ansible can act on failures
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT="${1:?Usage: $0 <migration_script> [args…]}"
shift || true                   # remaining args forwarded to the script

AUDIT_DIR="${AUDIT_DIR:-/var/log/ansible_onetime}"
LOG="${AUDIT_DIR}/wrapper_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$AUDIT_DIR"

exec_log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }

exec_log "=== WRAPPER START ==="
exec_log "Script : $SCRIPT"
exec_log "Args   : $*"
exec_log "User   : $(whoami)"
exec_log "PWD    : $(pwd)"

if [ ! -x "$SCRIPT" ]; then
  exec_log "ERROR: $SCRIPT is not executable or does not exist."
  exit 1
fi

exec_log "--- Executing ---"
set +e   # allow the script to fail without immediate exit
"$SCRIPT" "$@" 2>&1 | tee -a "$LOG"
RC=$?
set -e

exec_log "--- Finished (rc=$RC) ---"
exec_log "=== WRAPPER END ==="

exit $RC
