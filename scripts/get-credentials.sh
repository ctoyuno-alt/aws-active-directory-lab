#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - Fetch Credentials Script
# ==============================================================================
# Retrieves domain admin credentials from AWS SSM Parameter Store securely.
# Supports copying passwords directly to clipboard (wl-copy, xclip, pbcopy).
# ==============================================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Source Shared Bash Library ---
COMMON_LIB="${SCRIPT_DIR}/common.sh"
if [ -f "$COMMON_LIB" ]; then
    source "$COMMON_LIB"
else
    echo -e "\033[0;31m[ERROR]\033[0m Shared library common.sh not found at ${COMMON_LIB}" >&2
    exit 1
fi

SHOW_PASS=false
COPY_CLIPBOARD=false
REGION=""
PARAM_USER="/ad/corp.lab/domain-admin-username"
PARAM_PASS="/ad/corp.lab/domain-admin-password"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Fetches Active Directory credentials from AWS Systems Manager Parameter Store.

Options:
  -c, --copy              Copy password directly to system clipboard (wl-copy, xclip, pbcopy)
  -s, --show-password     Display plain-text password in terminal output (default: masked)
  -p, --profile PROFILE   AWS CLI profile to use (or set AWS_PROFILE env var)
  -r, --region REGION     AWS Region (default: derived from AWS CLI config)
  -h, --help              Display this help message and exit

Examples:
  $(basename "$0") --copy
  $(basename "$0") --show-password --profile aws-ad-lab
EOF
}

# --- Clipboard Helper Function ---
copy_to_clipboard() {
    local text="$1"
    if command -v wl-copy &> /dev/null; then
        echo -n "$text" | wl-copy
        return 0
    elif command -v xclip &> /dev/null; then
        echo -n "$text" | xclip -selection clipboard
        return 0
    elif command -v xsel &> /dev/null; then
        echo -n "$text" | xsel --clipboard --input
        return 0
    elif command -v pbcopy &> /dev/null; then
        echo -n "$text" | pbcopy
        return 0
    elif command -v clip.exe &> /dev/null; then
        echo -n "$text" | clip.exe
        return 0
    else
        return 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--copy)
            COPY_CLIPBOARD=true
            shift
            ;;
        -s|--show-password)
            SHOW_PASS=true
            shift
            ;;
        -p|--profile)
            AWS_PROFILE="$2"
            export AWS_PROFILE
            shift 2
            ;;
        -r|--region)
            REGION="$2"
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

if [ -z "$REGION" ]; then
    REGION=$(aws_cli configure get region 2>/dev/null || echo "ap-south-1")
fi

log_info "Fetching Active Directory credentials from Parameter Store (Region: ${REGION})..."

USERNAME=$(aws_cli ssm get-parameter --name "$PARAM_USER" --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null || echo "N/A")
PASSWORD=$(aws_cli ssm get-parameter --name "$PARAM_PASS" --with-decryption --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null || echo "N/A")

if [ "$USERNAME" == "N/A" ] || [ "$PASSWORD" == "N/A" ]; then
    log_error "Failed to retrieve parameters from AWS SSM Parameter Store."
    log_error "Verify that parameters '${PARAM_USER}' and '${PARAM_PASS}' exist and permissions are granted."
    exit 1
fi

log_success "Active Directory Credentials:"
echo "----------------------------------------"
echo -e "Domain:   ${GREEN}corp.lab${NC}"
echo -e "Username: ${GREEN}${USERNAME}${NC}"

COPIED=false
if [ "$COPY_CLIPBOARD" = true ]; then
    if copy_to_clipboard "$PASSWORD"; then
        COPIED=true
        log_success "Password: [COPIED TO CLIPBOARD]"
    else
        log_warn "No clipboard utility (wl-copy, xclip, xsel, pbcopy, clip.exe) found."
    fi
fi

if [ "$SHOW_PASS" = true ]; then
    echo -e "Password: ${YELLOW}${PASSWORD}${NC}"
elif [ "$COPIED" = false ]; then
    echo -e "Password: ${YELLOW}********${NC}  (use --copy or --show-password)"
fi
echo "----------------------------------------"
