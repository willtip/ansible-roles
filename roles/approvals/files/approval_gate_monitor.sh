#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# approval_gate_monitor.sh
# Dropped onto the target by the approvals role.
#
# Usage:  ./approval_gate_monitor.sh <decision_file> [timeout_seconds]
#
# Polls every 5 seconds until the decision file appears or timeout expires.
# Prints the decision to stdout on success; exits 1 on timeout.
# ---------------------------------------------------------------------------
set -euo pipefail

DECISION_FILE="${1:?Usage: $0 <decision_file> [timeout_seconds]}"
TIMEOUT="${2:-3600}"
POLL_INTERVAL=5
ELAPSED=0

echo "[gate-monitor] Watching: ${DECISION_FILE}"
echo "[gate-monitor] Timeout : ${TIMEOUT}s"

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  if [ -f "$DECISION_FILE" ]; then
    DECISION=$(cat "$DECISION_FILE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    echo "[gate-monitor] Decision received: ${DECISION}"
    exit 0
  fi
  sleep "$POLL_INTERVAL"
  ELAPSED=$(( ELAPSED + POLL_INTERVAL ))
  echo "[gate-monitor] Still waiting… (${ELAPSED}/${TIMEOUT}s)"
done

echo "[gate-monitor] TIMEOUT reached — no decision file found."
exit 1
