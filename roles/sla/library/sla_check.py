#!/usr/bin/python
# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# sla_check  —  Custom Ansible module
# Evaluates an SLA metric (uptime | response_time | error_rate) against
# its configured target and returns a structured verdict.
#
# EXAMPLES:
#   - sla_check:
#       metric_type: uptime
#       current_value: 99.85
#       target_value: 99.9
#       state_file: /var/lib/ansible_sla/uptime_state.json
#
# RETURNS:
#   breached  (bool)  – whether the target is violated
#   severity  (str)   – info | warning | critical
#   pct_used  (float) – fraction of the allowed budget consumed
# ---------------------------------------------------------------------------

from ansible.module_utils.basic import AnsibleModule
import json, os, time


def calculate_budget_used(current_value, target_value, metric_type):
    """
    For uptime   : budget = target - current  (lower current = more budget used)
    For response : budget = current - target  (higher current = more budget used)
    For error    : budget = current / target
    Returns (pct_used, breached)
    """
    if metric_type == "uptime":
        # e.g. target 99.9 -> allowed downtime = 0.1 %; current 99.85 -> used 0.05 %
        allowed_budget = 100.0 - target_value
        if allowed_budget == 0:
            return (1.0, current_value < target_value)
        used = (target_value - current_value) / allowed_budget
        return (max(0.0, used), current_value < target_value)

    elif metric_type == "response_time":
        # target is max ms; current is measured ms
        if target_value == 0:
            return (1.0, current_value > 0)
        pct = current_value / target_value
        return (pct, current_value > target_value)

    elif metric_type == "error_rate":
        if target_value == 0:
            return (1.0, current_value > 0)
        pct = current_value / target_value
        return (pct, current_value > target_value)

    return (0.0, False)


def determine_severity(pct_used, severity_map):
    if pct_used >= severity_map.get("critical", 1.0):
        return "critical"
    elif pct_used >= severity_map.get("warning", 0.8):
        return "warning"
    elif pct_used >= severity_map.get("info", 0.5):
        return "info"
    return "ok"


def persist_state(state_file, state_data):
    os.makedirs(os.path.dirname(state_file), exist_ok=True)
    with open(state_file, "w") as fh:
        json.dump(state_data, fh, indent=2)


def main():
    module = AnsibleModule(
        argument_spec=dict(
            metric_type=dict(type="str", required=True,
                             choices=["uptime", "response_time", "error_rate"]),
            current_value=dict(type="float", required=True),
            target_value=dict(type="float", required=True),
            state_file=dict(type="str", required=False, default=""),
            severity_map=dict(type="dict", required=False, default={
                "critical": 1.0, "warning": 0.8, "info": 0.5
            }),
        ),
        supports_check_mode=True,
    )

    metric_type   = module.params["metric_type"]
    current_value = module.params["current_value"]
    target_value  = module.params["target_value"]
    state_file    = module.params["state_file"]
    severity_map  = module.params["severity_map"]

    pct_used, breached = calculate_budget_used(current_value, target_value, metric_type)
    severity = determine_severity(pct_used, severity_map)

    result = dict(
        breached=breached,
        severity=severity,
        pct_used=round(pct_used, 4),
        metric_type=metric_type,
        current_value=current_value,
        target_value=target_value,
        evaluated_at=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    )

    # Persist state when a file path is provided (skip in check mode)
    if state_file and not module.check_mode:
        persist_state(state_file, result)

    module.exit_json(changed=breached, **result)


if __name__ == "__main__":
    main()
