#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - Infrastructure Deployment Script
# ==============================================================================
# Automates pre-flight checks, state bootstrapping, and Terraform deployment.
# ==============================================================================

set -euo pipefail

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
RUN_BOOTSTRAP=false

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Deploys the AWS Active Directory Lab infrastructure using Terraform.

Options:
  -e, --env ENVIRONMENT   Environment to deploy (default: dev)
  -b, --bootstrap         Run bootstrap step first to initialize S3/DynamoDB state backend
  -p, --profile PROFILE   AWS CLI profile to use (or set AWS_PROFILE env var)
  -y, --auto-approve      Automatically approve Terraform apply
  -h, --help              Display this help message and exit

Examples:
  $(basename "$0") --bootstrap --profile aws-ad-lab --auto-approve
  $(basename "$0") -e dev -p aws-ad-lab -y
EOF
}

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--env)
            ENV="$2"
            shift 2
            ;;
        -b|--bootstrap)
            RUN_BOOTSTRAP=true
            shift
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

# --- Pre-flight Checks ---
log_info "Running pre-flight system checks..."

if [ -n "$AWS_PROFILE" ]; then
    log_info "Using AWS Profile: ${AWS_PROFILE}"
fi

if ! command -v terraform &> /dev/null; then
    log_error "Terraform is not installed or not in PATH."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed or not in PATH."
    exit 1
fi

log_info "Verifying AWS authentication..."
if ! aws_cli sts get-caller-identity &> /dev/null; then
    log_error "Failed to authenticate with AWS. Check your AWS CLI credentials/profile."
    exit 1
fi
log_success "AWS Credentials verified."

# --- Step 1: Optional Bootstrapping ---
if [ "$RUN_BOOTSTRAP" = true ]; then
    BOOTSTRAP_DIR="${ROOT_DIR}/bootstrap"
    if [ -d "$BOOTSTRAP_DIR" ]; then
        log_info "Initializing and applying Terraform state bootstrap in bootstrap/..."
        cd "$BOOTSTRAP_DIR"
        terraform init
        terraform apply $AUTO_APPROVE
        log_success "Bootstrap completed."
    else
        log_error "Bootstrap directory not found at ${BOOTSTRAP_DIR}"
        exit 1
    fi
fi

# --- Step 2: Deploy Infrastructure Environment ---
ENV_DIR="${ROOT_DIR}/terraform/environments/${ENV}"

if [ ! -d "$ENV_DIR" ]; then
    log_error "Environment directory not found: ${ENV_DIR}"
    exit 1
fi

log_info "Deploying Terraform environment '${ENV}' in ${ENV_DIR}..."
cd "$ENV_DIR"

log_info "Initializing Terraform..."
terraform init

log_info "Validating configuration..."
terraform validate

log_info "Applying Terraform configuration..."
terraform apply $AUTO_APPROVE

log_success "Deployment completed successfully for environment '${ENV}'!"
