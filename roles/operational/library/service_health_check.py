#!/usr/bin/python
# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# service_health_check  —  Custom Ansible module
# Queries a systemd service via systemctl and returns structured health info.
#
# EXAMPLES:
#   - service_health_check:
#       service_name: nginx
#       healthy_states: ['running']
#
# RETURNS:
#   name        (str)   – the service name
#   state       (str)   – current systemctl state
#   healthy     (bool)  – whether state is in healthy_states
#   pid         (str)   – main PID or "0" if not running
#   uptime_s    (int)   – seconds since the service started (0 if not running)
# ---------------------------------------------------------------------------

import subprocess, re
from ansible.module_utils.basic import AnsibleModule


def get_service_state(service_name):
    """Return (state, pid, start_epoch) from systemctl show."""
    result = {
        "state": "unknown",
        "pid": "0",
        "start_epoch": 0,
    }
    try:
        raw = subprocess.run(
            ["systemctl", "show", "--property=ActiveState,MainPID,ActiveEnterTimestamp", service_name],
            capture_output=True, text=True, timeout=5
        )
        for line in raw.stdout.splitlines():
            if line.startswith("ActiveState="):
                result["state"] = line.split("=", 1)[1].strip()
            elif line.startswith("MainPID="):
                result["pid"] = line.split("=", 1)[1].strip()
            elif line.startswith("ActiveEnterTimestamp="):
                # Parse epoch from "Wed 2024-01-15 12:00:00 UTC 1705312800123456"
                parts = line.split("=", 1)[1].strip().split()
                if parts:
                    # Last element is typically the epoch microseconds
                    try:
                        result["start_epoch"] = int(parts[-1]) // 1_000_000
                    except ValueError:
                        pass
    except (subprocess.SubprocessError, FileNotFoundError):
        pass
    return result


def main():
    module = AnsibleModule(
        argument_spec=dict(
            service_name=dict(type="str", required=True),
            healthy_states=dict(type="list", elements="str", default=["running"]),
        ),
        supports_check_mode=True,
    )

    service_name  = module.params["service_name"]
    healthy_states = [s.lower() for s in module.params["healthy_states"]]

    info = get_service_state(service_name)

    import time
    now = int(time.time())
    uptime_s = now - info["start_epoch"] if info["start_epoch"] > 0 else 0
    healthy  = info["state"].lower() in healthy_states

    module.exit_json(
        changed=False,
        name=service_name,
        state=info["state"],
        healthy=healthy,
        pid=info["pid"],
        uptime_s=uptime_s,
    )


if __name__ == "__main__":
    main()
