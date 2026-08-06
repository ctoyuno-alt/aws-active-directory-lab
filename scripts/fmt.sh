#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - Terraform Formatting Helper Script
# ==============================================================================
# Formats all Terraform configuration files recursively across the project.
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

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Runs 'terraform fmt -recursive' across the entire repository to format HCL files.

Options:
  -h, --help    Display this help message and exit

Example:
  $(basename "$0")
EOF
}

if [[ $# -gt 0 ]]; then
    case "$1" in
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
fi

log_info "Formatting Terraform files recursively across repository..."
terraform fmt -recursive "${ROOT_DIR}"
log_success "Terraform formatting completed!"
