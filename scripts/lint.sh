#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - Multi-Language Code Linter Suite
# ==============================================================================
# Executes static analysis and validation across Terraform, Bash, and PowerShell:
#   1. terraform fmt -check -recursive
#   2. terraform validate
#   3. ShellCheck / bash -n (Bash script validation)
#   4. PSScriptAnalyzer (PowerShell script validation via pwsh)
# ==============================================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# --- Source Shared Bash Library ---
COMMON_LIB="${SCRIPT_DIR}/common.sh"
if [ -f "$COMMON_LIB" ]; then
    source "$COMMON_LIB"
else
    echo -e "\033[0;31m[ERROR]\033[0m Shared library common.sh not found at ${COMMON_LIB}" >&2
    exit 1
fi

ENV="all"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Runs complete linting and static analysis suite:
  - Terraform formatting check & validation
  - Bash syntax & ShellCheck linting
  - PowerShell PSScriptAnalyzer linting

Options:
  -e, --env ENVIRONMENT   Environment to validate (e.g. dev, prod, or 'all', default: all)
  -p, --profile PROFILE   AWS CLI profile to use (or set AWS_PROFILE env var)
  -h, --help              Display this help message and exit

Examples:
  $(basename "$0")
  $(basename "$0") --env dev --profile aws-ad-lab
EOF
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--env)
            ENV="$2"
            shift 2
            ;;
        -p|--profile)
            AWS_PROFILE="$2"
            export AWS_PROFILE
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

LINT_FAILED=false

log_info "=========================================================="
log_info "Starting Repository Multi-Language Linting Suite"
log_info "=========================================================="

# ------------------------------------------------------------------------------
# 1. Terraform Formatting Check
# ------------------------------------------------------------------------------
log_info "[1/4] Checking Terraform formatting (terraform fmt -check -recursive)..."
if terraform fmt -check -recursive "${ROOT_DIR}"; then
    log_success "Terraform formatting check passed!"
else
    log_error "Terraform formatting check failed! Run './scripts/fmt.sh' to fix."
    LINT_FAILED=true
fi

# ------------------------------------------------------------------------------
# 2. Terraform Code Validation
# ------------------------------------------------------------------------------
log_info "[2/4] Validating Terraform modules and environments..."

validate_tf_dir() {
    local target_dir="$1"
    local name="$2"

    if [ ! -d "$target_dir" ]; then
        log_warn "Terraform directory not found, skipping: ${target_dir}"
        return 0
    fi

    log_info "Validating Terraform code in '${name}'..."
    (
        cd "$target_dir"
        terraform init -backend=false > /dev/null
        terraform validate
    ) || {
        log_error "Terraform validation failed for '${name}'!"
        LINT_FAILED=true
    }
}

validate_tf_dir "${ROOT_DIR}/bootstrap" "bootstrap"

if [ "$ENV" = "all" ]; then
    for env_dir in "${ROOT_DIR}/terraform/environments"/*; do
        if [ -d "$env_dir" ]; then
            env_name="$(basename "$env_dir")"
            validate_tf_dir "$env_dir" "environment:${env_name}"
        fi
    done
else
    validate_tf_dir "${ROOT_DIR}/terraform/environments/${ENV}" "environment:${ENV}"
fi

# ------------------------------------------------------------------------------
# 3. Bash Scripts Validation (ShellCheck / bash -n)
# ------------------------------------------------------------------------------
log_info "[3/4] Linting Bash wrapper scripts..."

BASH_SCRIPTS=()
while IFS= read -r -d '' script_file; do
    BASH_SCRIPTS+=("$script_file")
done < <(find "${ROOT_DIR}/scripts" "${ROOT_DIR}/userdata/linux" -type f -name "*.sh" -print0 2>/dev/null || true)

if [ ${#BASH_SCRIPTS[@]} -gt 0 ]; then
    log_info "Checking syntax for ${#BASH_SCRIPTS[@]} Bash scripts (bash -n)..."
    for bscript in "${BASH_SCRIPTS[@]}"; do
        if bash -n "$bscript"; then
            log_success "Syntax check passed: $(basename "$bscript")"
        else
            log_error "Syntax error in Bash script: $bscript"
            LINT_FAILED=true
        fi
    done

    if command -v shellcheck &> /dev/null; then
        log_info "Running ShellCheck static analysis..."
        if shellcheck "${BASH_SCRIPTS[@]}"; then
            log_success "ShellCheck analysis passed!"
        else
            log_error "ShellCheck found issues in Bash scripts."
            LINT_FAILED=true
        fi
    else
        log_warn "ShellCheck is not installed. Skipping deep ShellCheck analysis."
    fi
else
    log_info "No Bash scripts found to lint."
fi

# ------------------------------------------------------------------------------
# 4. PowerShell Scripts Validation (PSScriptAnalyzer via pwsh)
# ------------------------------------------------------------------------------
log_info "[4/4] Linting PowerShell scripts (PSScriptAnalyzer)..."

if command -v pwsh &> /dev/null; then
    log_info "Executing PSScriptAnalyzer via PowerShell Core (pwsh)..."
    PWSH_CMD="if (Get-Module -ListAvailable -Name PSScriptAnalyzer) { Invoke-ScriptAnalyzer -Path '${ROOT_DIR}/powershell' -Recurse } else { Write-Warning 'PSScriptAnalyzer module not installed.' }"
    if pwsh -Command "$PWSH_CMD"; then
        log_success "PowerShell linting completed!"
    else
        log_error "PSScriptAnalyzer detected issues in PowerShell scripts."
        LINT_FAILED=true
    fi
else
    log_warn "PowerShell Core (pwsh) is not installed locally. Skipping PSScriptAnalyzer check."
    log_info "Note: PSScriptAnalyzer will execute automatically when pwsh / CI runners are available."
fi

# ------------------------------------------------------------------------------
# Final Summary
# ------------------------------------------------------------------------------
echo "=========================================================="
if [ "$LINT_FAILED" = true ]; then
    log_error "Linting suite completed with errors! Please fix issues above."
    exit 1
else
    log_success "All linting & validation checks passed successfully!"
    echo "=========================================================="
    exit 0
fi
