#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deep_scan.sh  —  dropped onto the target by the troubleshooting role.
# Performs:
#   1. Open-port enumeration (ss)
#   2. Stale-lock-file detection under /var/run and /tmp
#   3. Core-dump presence check
# ---------------------------------------------------------------------------
set -euo pipefail

echo "========================================="
echo " DEEP SCAN — $(hostname) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "========================================="

# --- 1. Open ports --------------------------------------------------------
echo ""
echo ">>> OPEN PORTS (TCP + UDP) <<<"
ss -tlnup 2>/dev/null || netstat -tlnup 2>/dev/null || echo "  [warn] no ss or netstat available"

echo ""
echo ">>> LISTENING UNIX SOCKETS <<<"
ss -lnx 2>/dev/null | head -40 || echo "  [warn] unix socket listing unavailable"

# --- 2. Stale lock files --------------------------------------------------
echo ""
echo ">>> STALE LOCK FILES (mtime > 1 hour) <<<"
find /var/run /tmp -name "*.lock" -o -name "*.pid" 2>/dev/null | while read -r f; do
  age_seconds=$(( $(date +%s) - $(stat -c %Y "$f" 2>/dev/null || echo 0) ))
  if [ "$age_seconds" -gt 3600 ]; then
    echo "  STALE ($age_seconds s): $f"
  fi
done

# --- 3. Core dumps -------------------------------------------------------
echo ""
echo ">>> CORE DUMPS (last 24 h) <<<"
CORE_PATTERN=$(cat /proc/sys/kernel/core_pattern 2>/dev/null || echo "core")
echo "  core_pattern = $CORE_PATTERN"
find /var/crash /tmp /var/lib -name "core*" -mmin -1440 2>/dev/null | head -20
# Also check systemd-coredump if present
coredumpctl list --no-pager 2>/dev/null | tail -20 || echo "  [info] coredumpctl not available"

echo ""
echo "========================================="
echo " DEEP SCAN COMPLETE"
echo "========================================="
