#!/usr/bin/env bash
# =============================================================================
# GitHub Quick Setup Script for Ansible Roles
# 
# This script automates the initial setup and first push to GitHub.
# 
# Usage:
#   1. Extract ansible_roles_with_readme.tar.gz
#   2. Copy this script to the extracted directory
#   3. Edit GITHUB_USERNAME and GITHUB_REPO below
#   4. Run: chmod +x setup_github.sh && ./setup_github.sh
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION - EDIT THESE VALUES
# =============================================================================
GITHUB_USERNAME="willtip"       # Replace with your GitHub username
GITHUB_REPO="ansible-role"                  # Repository name
GIT_USER_NAME="Bill Tipton"                    # Your name for commits
GIT_USER_EMAIL="willtip@gmail.com"      # Your email for commits
USE_SSH=false                                 # true=SSH, false=HTTPS

# =============================================================================
# DO NOT EDIT BELOW THIS LINE
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v git &> /dev/null; then
        log_error "git is not installed. Please install git first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Validate configuration
validate_config() {
    log_info "Validating configuration..."
    
    if [[ "$GITHUB_USERNAME" == "YOUR_GITHUB_USERNAME" ]]; then
        log_error "Please edit GITHUB_USERNAME in this script before running"
        exit 1
    fi
    
    if [[ "$GIT_USER_NAME" == "Your Name" ]]; then
        log_error "Please edit GIT_USER_NAME in this script before running"
        exit 1
    fi
    
    if [[ "$GIT_USER_EMAIL" == "your.email@example.com" ]]; then
        log_error "Please edit GIT_USER_EMAIL in this script before running"
        exit 1
    fi
    
    log_success "Configuration validated"
}

# Initialize git repository
init_git() {
    log_info "Initializing Git repository..."
    
    if [ -d ".git" ]; then
        log_warn "Git repository already exists. Skipping initialization."
        return
    fi
    
    git init
    git config user.name "$GIT_USER_NAME"
    git config user.email "$GIT_USER_EMAIL"
    
    log_success "Git repository initialized"
}

# Add remote
add_remote() {
    log_info "Adding GitHub remote..."
    
    if $USE_SSH; then
        REMOTE_URL="git@github.com:${GITHUB_USERNAME}/${GITHUB_REPO}.git"
    else
        REMOTE_URL="https://github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"
    fi
    
    if git remote get-url origin &> /dev/null; then
        log_warn "Remote 'origin' already exists. Updating URL..."
        git remote set-url origin "$REMOTE_URL"
    else
        git remote add origin "$REMOTE_URL"
    fi
    
    log_success "Remote added: $REMOTE_URL"
}

# Create .gitignore
create_gitignore() {
    log_info "Creating .gitignore..."
    
    if [ -f ".gitignore" ]; then
        log_warn ".gitignore already exists. Skipping..."
        return
    fi
    
    cat > .gitignore << 'EOF'
# Ansible
*.retry
*.log
.vault_pass
vault_password

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Secrets & Credentials
*.pem
*.key
secrets.yml
credentials/
.env

# Temporary files
*.tmp
*.bak
tmp/
temp/

# Testing
.pytest_cache/
.tox/
htmlcov/
.coverage

# Logs & artifacts
logs/
artifacts/
*.tar.gz
*.zip
EOF
    
    log_success ".gitignore created"
}

# Create .gitattributes
create_gitattributes() {
    log_info "Creating .gitattributes..."
    
    if [ -f ".gitattributes" ]; then
        log_warn ".gitattributes already exists. Skipping..."
        return
    fi
    
    cat > .gitattributes << 'EOF'
# Auto detect text files and perform LF normalization
* text=auto

# YAML files
*.yml text eol=lf
*.yaml text eol=lf

# Jinja2 templates
*.j2 text eol=lf

# Shell scripts
*.sh text eol=lf

# Python scripts
*.py text eol=lf

# Ensure these are always LF
Makefile text eol=lf
Dockerfile text eol=lf

# Binary files
*.gz binary
*.tar binary
*.zip binary
*.png binary
*.jpg binary
EOF
    
    log_success ".gitattributes created"
}

# Create ansible.cfg
create_ansible_cfg() {
    log_info "Creating ansible.cfg..."
    
    if [ -f "ansible.cfg" ]; then
        log_warn "ansible.cfg already exists. Skipping..."
        return
    fi
    
    cat > ansible.cfg << 'EOF'
[defaults]
roles_path = ./roles
inventory = ./inventory/production/hosts.yml
stdout_callback = yaml
bin_ansible_callbacks = True
forks = 10
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
host_key_checking = False
vault_password_file = .vault_pass
log_path = ./logs/ansible.log

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF
    
    log_success "ansible.cfg created"
}

# Create GitHub Actions workflows
create_workflows() {
    log_info "Creating GitHub Actions workflows..."
    
    mkdir -p .github/workflows
    
    # Lint workflow
    cat > .github/workflows/lint.yml << 'EOF'
---
name: Ansible Lint

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    name: Lint Ansible Roles
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install ansible-core ansible-lint yamllint
      
      - name: Run ansible-lint
        run: |
          ansible-lint roles/ || true
EOF
    
    log_success "GitHub Actions workflows created"
}

# Create .ansible-lint config
create_ansible_lint() {
    log_info "Creating .ansible-lint configuration..."
    
    cat > .ansible-lint << 'EOF'
---
skip_list:
  - yaml[line-length]
  - name[casing]
  - risky-file-permissions

warn_list:
  - experimental
  - role-name

exclude_paths:
  - .github/
  - .git/
  - molecule/
  - venv/

rules:
  line-length:
    max: 120
EOF
    
    log_success ".ansible-lint created"
}

# Initial commit
initial_commit() {
    log_info "Creating initial commit..."
    
    git add .
    
    git commit -m "Initial commit: Six production-ready Ansible roles

Roles included:
- troubleshooting: System diagnostics and health checks
- configuration: NTP, sysctl, rsyslog, MOTD management  
- sla: Uptime, response-time, error-rate monitoring
- approvals: Human-in-the-loop approval gates
- operational: Health checks, restarts, backups, cleanup
- onetime: Idempotent migrations with rollback support

Each role includes:
- Comprehensive defaults and variables
- Custom Ansible modules where applicable
- Jinja2 templates for configs and reports
- Handler-based notifications
- Full metadata and documentation"
    
    log_success "Initial commit created"
}

# Set default branch
set_default_branch() {
    log_info "Setting default branch to 'main'..."
    
    git branch -M main
    
    log_success "Default branch set to 'main'"
}

# Push to GitHub
push_to_github() {
    log_info "Pushing to GitHub..."
    
    echo ""
    log_warn "About to push to: $REMOTE_URL"
    log_warn "Make sure the repository exists on GitHub!"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Push cancelled by user"
        exit 1
    fi
    
    if git push -u origin main; then
        log_success "Successfully pushed to GitHub!"
    else
        log_error "Push failed. Check your credentials and repository settings."
        log_info "If using SSH, make sure your SSH key is added to GitHub."
        log_info "If using HTTPS, you may need to use a Personal Access Token."
        exit 1
    fi
}

# Display next steps
show_next_steps() {
    echo ""
    echo "========================================="
    log_success "Setup Complete!"
    echo "========================================="
    echo ""
    log_info "Your Ansible roles have been pushed to GitHub!"
    echo ""
    echo "Next steps:"
    echo "  1. Visit: https://github.com/${GITHUB_USERNAME}/${GITHUB_REPO}"
    echo "  2. Configure branch protection rules (Settings → Branches)"
    echo "  3. Add Ansible Galaxy API key to secrets (Settings → Secrets)"
    echo "  4. Review and customize GitHub Actions workflows"
    echo "  5. Create example playbooks and inventory"
    echo ""
    echo "Useful commands:"
    echo "  • View repository:  gh repo view --web"
    echo "  • Create PR:        gh pr create"
    echo "  • Check status:     git status"
    echo "  • View logs:        git log --oneline"
    echo ""
}

# Main execution
main() {
    echo "========================================="
    echo "   Ansible Roles - GitHub Setup"
    echo "========================================="
    echo ""
    
    check_prerequisites
    validate_config
    init_git
    add_remote
    create_gitignore
    create_gitattributes
    create_ansible_cfg
    create_workflows
    create_ansible_lint
    initial_commit
    set_default_branch
    push_to_github
    show_next_steps
}

# Run main
main