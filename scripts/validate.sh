#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - Terraform Pre-Commit Validation Script
# ==============================================================================
# Performs formatting checks, configuration validations, and execution planning
# across Terraform modules and environments before committing code.
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
SKIP_PLAN=false

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Runs pre-commit checks on Terraform code:
  1. terraform fmt -check -recursive
  2. terraform validate
  3. terraform plan

Options:
  -e, --env ENVIRONMENT   Environment to validate (e.g. dev, prod, or 'all', default: all)
  -p, --profile PROFILE   AWS CLI profile to use (or set AWS_PROFILE env var)
  --skip-plan             Skip terraform plan phase (formatting & validate only)
  -h, --help              Display this help message and exit

Examples:
  $(basename "$0")
  $(basename "$0") -e dev --profile aws-ad-lab
  $(basename "$0") --skip-plan
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
        --skip-plan)
            SKIP_PLAN=true
            shift
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

log_info "Starting pre-commit Terraform validation suite..."

if ! command -v terraform &> /dev/null; then
    log_error "Terraform is not installed or not in PATH."
    exit 1
fi

# 1. Check formatting recursively across repository
log_info "Phase 1: Checking Terraform formatting (terraform fmt -check -recursive)..."
if terraform fmt -check -recursive "${ROOT_DIR}"; then
    log_success "Formatting check passed!"
else
    log_error "Terraform formatting check failed! Run 'terraform fmt -recursive' to fix formatting."
    exit 1
fi

# Function to validate and plan a terraform directory
validate_directory() {
    local target_dir="$1"
    local name="$2"

    if [ ! -d "$target_dir" ]; then
        log_warn "Directory not found, skipping: ${target_dir}"
        return 0
    fi

    log_info "Phase 2: Validating Terraform code in '${name}' (${target_dir})..."
    cd "$target_dir"

    log_info "Initializing Terraform (${name})..."
    terraform init -backend=false > /dev/null

    log_info "Validating configuration (${name})..."
    terraform validate

    log_success "Validation passed for '${name}'!"

    if [ "$SKIP_PLAN" = false ]; then
        log_info "Phase 3: Generating execution plan (terraform plan) for '${name}'..."
        terraform init > /dev/null
        terraform plan
        log_success "Terraform plan succeeded for '${name}'!"
    fi
}

# 2. Validate bootstrap directory
validate_directory "${ROOT_DIR}/bootstrap" "bootstrap"

# 3. Validate target environment directories
if [ "$ENV" = "all" ]; then
    for env_dir in "${ROOT_DIR}/terraform/environments"/*; do
        if [ -d "$env_dir" ]; then
            env_name="$(basename "$env_dir")"
            validate_directory "$env_dir" "environment:${env_name}"
        fi
    done
else
    validate_directory "${ROOT_DIR}/terraform/environments/${ENV}" "environment:${ENV}"
fi

log_success "=========================================================="
log_success "All pre-commit validations passed successfully!"
log_success "=========================================================="
