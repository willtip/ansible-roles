# Ansible Roles - Category-Based Automation Framework

This repository contains six production-ready Ansible roles organized by operational category. Each role follows the standard Ansible role directory structure and includes comprehensive defaults, variables, tasks, handlers, templates, and custom modules where applicable.

## Directory Structure

```
roles/
├── README.md                          # This file
│
├── troubleshooting/                   # CATEGORY: Troubleshooting & Diagnostics
│   ├── tasks/
│   │   └── main.yml                   # Entry point: orchestrates diagnostic workflow
│   ├── handlers/
│   │   └── main.yml                   # Notification & cleanup handlers
│   ├── templates/
│   │   └── diag_report.txt.j2         # Human-readable diagnostic summary
│   ├── files/
│   │   └── deep_scan.sh               # Port/lock/core-dump scanner script
│   ├── vars/
│   │   └── main.yml                   # Internal depth maps & script references
│   ├── defaults/
│   │   └── main.yml                   # Safe defaults for depth, retention, paths
│   └── meta/
│       └── main.yml                   # Role metadata & dependencies
│
├── configuration/                     # CATEGORY: Configuration Management
│   ├── tasks/
│   │   ├── main.yml                   # Entry point: includes sub-task files
│   │   ├── ntp.yml                    # NTP/chrony configuration
│   │   ├── sysctl.yml                 # Kernel tuning parameters
│   │   ├── rsyslog.yml                # Centralized logging setup
│   │   └── motd.yml                   # Login banner management
│   ├── handlers/
│   │   └── main.yml                   # Service restart handlers
│   ├── templates/
│   │   ├── chrony.conf.j2             # NTP configuration template
│   │   ├── rsyslog_remote.conf.j2     # Remote syslog forwarder
│   │   └── motd.j2                    # Message-of-the-day banner
│   ├── vars/
│   │   └── main.yml                   # OS-family package maps
│   ├── defaults/
│   │   └── main.yml                   # Config toggles & safe defaults
│   └── meta/
│       └── main.yml                   # Role metadata
│
├── sla/                               # CATEGORY: SLA Monitoring & Alerting
│   ├── tasks/
│   │   └── main.yml                   # Entry point: uptime/response/error checks
│   ├── handlers/
│   │   └── main.yml                   # Slack & PagerDuty breach notifications
│   ├── library/
│   │   └── sla_check.py               # Custom module: SLA evaluation logic
│   ├── templates/
│   │   └── sla_alert.txt.j2           # Breach alert report
│   ├── vars/
│   │   └── main.yml                   # Severity maps & state-file names
│   ├── defaults/
│   │   └── main.yml                   # SLA targets, thresholds, endpoints
│   └── meta/
│       └── main.yml                   # Role metadata
│
├── approvals/                         # CATEGORY: Approval Gates & Workflow
│   ├── tasks/
│   │   └── main.yml                   # Entry point: request → poll → decide
│   ├── handlers/
│   │   └── main.yml                   # Escalation notification handler
│   ├── templates/
│   │   ├── approval_request.txt.j2    # Request message template
│   │   └── escalation_alert.txt.j2    # Escalation alert template
│   ├── files/
│   │   └── approval_gate_monitor.sh   # Standalone gate-monitoring script
│   ├── vars/
│   │   └── main.yml                   # Valid decisions & file-naming convention
│   ├── defaults/
│   │   └── main.yml                   # Timeout, polling, escalation config
│   └── meta/
│       └── main.yml                   # Role metadata
│
├── operational/                       # CATEGORY: Operational Maintenance
│   ├── tasks/
│   │   ├── main.yml                   # Entry point: orchestrates ops workflow
│   │   ├── health_check.yml           # Service health checks
│   │   ├── restart.yml                # Graceful service restarts
│   │   ├── housekeeping.yml           # Disk cleanup
│   │   ├── backup.yml                 # Backup & rotation
│   │   └── report.yml                 # Summary report generation
│   ├── handlers/
│   │   └── main.yml                   # Post-restart notifications
│   ├── library/
│   │   └── service_health_check.py    # Custom module: systemd health queries
│   ├── templates/
│   │   └── ops_run_report.txt.j2      # Operations summary report
│   ├── vars/
│   │   └── main.yml                   # Internal paths & module reference
│   ├── defaults/
│   │   └── main.yml                   # Services, grace periods, retention
│   └── meta/
│       └── main.yml                   # Role metadata
│
└── onetime/                           # CATEGORY: One-Time Migrations & Setup
    ├── tasks/
    │   ├── main.yml                   # Entry point: idempotency → execute → marker
    │   └── rollback.yml               # Rollback task file (for rescue blocks)
    ├── handlers/
    │   └── main.yml                   # Success & rollback notifications
    ├── templates/
    │   └── onetime_summary.txt.j2     # Migration summary report
    ├── files/
    │   └── onetime_wrapper.sh         # Generic wrapper for migration scripts
    ├── vars/
    │   └── main.yml                   # Internal paths & template references
    ├── defaults/
    │   └── main.yml                   # Operation ID, force flag, rollback config
    └── meta/
        └── main.yml                   # Role metadata
```

## Role Categories & Entry Points

| Category                | Role Name         | Entry Point              | Purpose                                    |
|-------------------------|-------------------|--------------------------|--------------------------------------------|
| **Troubleshooting**     | troubleshooting   | tasks/main.yml           | System diagnostics, log scraping, profiling|
| **Configuration**       | configuration     | tasks/main.yml           | NTP, sysctl, rsyslog, MOTD management      |
| **SLA Related**         | sla               | tasks/main.yml           | Uptime, response-time, error-rate monitoring|
| **Approvals Needed**    | approvals         | tasks/main.yml           | Human-in-the-loop approval gates           |
| **Operational**         | operational       | tasks/main.yml           | Health checks, restarts, backups, cleanup  |
| **One Time Only**       | onetime           | tasks/main.yml           | Idempotent migrations with rollback support|

## Standard Directory Layout (per role)

Each role uses up to 8 standard Ansible directories:

```
<role_name>/
├── tasks/           # YAML task files (entry point: main.yml)
├── handlers/        # Event-driven tasks triggered by notify
├── templates/       # Jinja2 templates (.j2 files)
├── files/           # Static files copied to targets
├── vars/            # Higher-precedence variables
├── defaults/        # Low-precedence, easily overridable defaults
├── meta/            # Role metadata (author, platforms, dependencies)
├── library/         # Custom Ansible modules (Python)
├── module_utils/    # Shared Python utilities for custom modules
└── lookup_plugins/  # Custom lookup plugins
```

**Note**: Only directories actually used by each role are included. Empty directories are omitted.

## Usage Example

### Single Role Invocation

```yaml
---
- name: Run troubleshooting diagnostics
  hosts: webservers
  roles:
    - role: troubleshooting
      vars:
        troubleshooting_depth: deep
        troubleshooting_services:
          - nginx
          - postgresql
```

### Multi-Role Workflow

```yaml
---
- name: Complete operational workflow with approval gate
  hosts: production
  roles:
    # 1. Verify configuration baseline
    - role: configuration
      vars:
        configuration_ntp_enabled: true
        configuration_sysctl_enabled: true

    # 2. Check SLA compliance before changes
    - role: sla
      vars:
        sla_uptime_target_percent: 99.95
        sla_response_endpoints:
          - https://api.example.com/health

    # 3. Human approval required before proceeding
    - role: approvals
      vars:
        approvals_gate_name: "production_restart_gate"
        approvals_timeout_seconds: 1800

    # 4. Execute operational maintenance
    - role: operational
      vars:
        operational_services:
          - nginx
          - redis
          - app-server
        operational_backup_enabled: true
        operational_backup_targets:
          - /var/lib/redis
          - /opt/app/data

    # 5. One-time database migration (idempotent)
    - role: onetime
      vars:
        onetime_operation_id: "migrate_db_schema_v2"
        onetime_migration_script: "files/migrate_db.sh"
        onetime_rollback_script: "files/rollback_db.sh"
        onetime_rollback_on_failure: true

    # 6. Post-change diagnostics
    - role: troubleshooting
      vars:
        troubleshooting_depth: basic
```

## Key Features by Role

### troubleshooting
- ✅ Three-tier diagnostic depth (basic/deep/full)
- ✅ Log scraping with configurable patterns
- ✅ Port scanning, stale-lock detection, core-dump analysis
- ✅ Thread-dump capture for Java processes
- ✅ Network packet capture (tcpdump)
- ✅ Slack notifications on findings

### configuration
- ✅ Idempotent config management
- ✅ Automatic backup before overwrite
- ✅ Modular sub-tasks (NTP, sysctl, rsyslog, MOTD)
- ✅ OS-family abstraction for package names
- ✅ Service restart only when config changes

### sla
- ✅ Custom `sla_check` Ansible module
- ✅ Three metric types: uptime, response-time, error-rate
- ✅ Severity tiers: ok/info/warning/critical
- ✅ Budget-consumption calculation
- ✅ Persistent state tracking
- ✅ Slack + PagerDuty integration

### approvals
- ✅ Configurable timeout and polling intervals
- ✅ Escalation workflow for stale approvals
- ✅ Fail-safe: timeout action = fail or skip
- ✅ File-based decision backend
- ✅ Full audit trail

### operational
- ✅ Custom `service_health_check` module
- ✅ Graceful stop → grace window → restart
- ✅ Disk housekeeping (stale file purge)
- ✅ Backup with generation-based rotation
- ✅ Comprehensive run report

### onetime
- ✅ Marker-file idempotency (no re-runs)
- ✅ Pre-flight check gate
- ✅ Rollback script on failure
- ✅ Force flag for emergency re-execution
- ✅ Full audit logging

## Custom Modules

Two roles ship with custom Ansible modules in `library/`:

**sla/library/sla_check.py**
- Evaluates SLA metrics against targets
- Returns: breached (bool), severity (str), pct_used (float)
- Persists state to JSON files

**operational/library/service_health_check.py**
- Queries systemd service status
- Returns: state, healthy (bool), pid, uptime_s
- Works with any systemd-managed service

## File Artifacts

### Static Scripts (files/)
- `troubleshooting/files/deep_scan.sh` — Port/lock/core scanner
- `approvals/files/approval_gate_monitor.sh` — Standalone gate monitor
- `onetime/files/onetime_wrapper.sh` — Migration script wrapper

### Templates (templates/)
All roles include Jinja2 templates for:
- Configuration files (chrony, rsyslog, motd)
- Reports (diagnostic, SLA breach, operational summary, onetime migration)
- Notifications (approval requests, escalation alerts)

## Variable Precedence

Each role uses the standard Ansible variable precedence:

1. **defaults/main.yml** — Lowest precedence, easily overridden
2. **vars/main.yml** — Higher precedence, environment-specific
3. **Playbook vars** — Highest precedence (use this to customize at runtime)

Example:
```yaml
# defaults/main.yml (role default)
troubleshooting_depth: basic

# vars/main.yml (environment override)
# (not typically overridden here)

# playbook (runtime override — WINS)
- role: troubleshooting
  vars:
    troubleshooting_depth: full
```

## Installation

```bash
# Extract the archive
tar -xzf ansible_roles.tar.gz

# Place in your Ansible project
mv roles/ /path/to/your/ansible/project/

# Verify structure
tree roles/
```

## Requirements

- Ansible >= 2.14
- Python >= 3.8 (for custom modules)
- Target systems: Ubuntu 20.04+, CentOS/RHEL 8+

## License

MIT

## Author

Platform Engineering Team
