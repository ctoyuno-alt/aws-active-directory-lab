#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - Infrastructure Tear Down Script
# ==============================================================================
# Destroys the specified Terraform environment safely with confirmation prompts.
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

# --- Default Variables ---
ENV="dev"
AUTO_APPROVE=""

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Tears down / destroys the AWS Active Directory Lab infrastructure.

Options:
  -e, --env ENVIRONMENT   Environment to destroy (default: dev)
  -p, --profile PROFILE   AWS CLI profile to use (or set AWS_PROFILE env var)
  -y, --auto-approve      Skip interactive confirmation prompt
  -h, --help              Display this help message and exit

Examples:
  $(basename "$0") -e dev --profile aws-ad-lab
  $(basename "$0") -e dev -y
EOF
}

# --- Parse Arguments ---
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
        -y|--auto-approve)
            AUTO_APPROVE="-auto-approve"
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

ENV_DIR="${ROOT_DIR}/terraform/environments/${ENV}"

if [ ! -d "$ENV_DIR" ]; then
    log_error "Environment directory not found: ${ENV_DIR}"
    exit 1
fi

if [ -n "$AWS_PROFILE" ]; then
    log_info "Using AWS Profile: ${AWS_PROFILE}"
fi

log_warn "WARNING: You are about to destroy all resources in environment '${ENV}'!"

if [ -z "$AUTO_APPROVE" ]; then
    read -p "Are you sure you want to destroy environment '${ENV}'? (type 'yes' to confirm): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        log_info "Tear down aborted by user."
        exit 0
    fi
fi

cd "$ENV_DIR"

log_info "Running Terraform destroy on '${ENV}'..."
terraform destroy $AUTO_APPROVE

log_success "Environment '${ENV}' destroyed successfully."
