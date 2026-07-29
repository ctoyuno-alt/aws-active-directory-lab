#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - SSM Connect Wrapper Script
# ==============================================================================
# Easily open an AWS SSM Session Manager shell or PowerShell session to DC01/DC02.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Source Shared Bash Library ---
COMMON_LIB="${SCRIPT_DIR}/common.sh"
if [ -f "$COMMON_LIB" ]; then
    source "$COMMON_LIB"
else
    echo -e "\033[0;31m[ERROR]\033[0m Shared library common.sh not found at ${COMMON_LIB}" >&2
    exit 1
fi

TARGET="DC01"
REGION=""
MODE="cmd" # options: cmd, powershell

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TARGET]

Connects to a Domain Controller or instance using AWS SSM Session Manager.

TARGET:
  DC01 (default), DC02, or a specific EC2 Instance ID (e.g. i-0123456789abcdef0)

Options:
  -p, --profile PROFILE   AWS CLI profile to use (or set AWS_PROFILE env var)
  -w, --powershell        Start an interactive PowerShell session (AWS-StartPSSession)
  -r, --region REGION     AWS Region (default: derived from AWS CLI config)
  -h, --help              Display this help message and exit

Examples:
  $(basename "$0") DC01
  $(basename "$0") DC02 --powershell --profile aws-ad-lab
  $(basename "$0") i-0123456789abcdef0
EOF
}

# Parse options
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--profile)
            AWS_PROFILE="$2"
            export AWS_PROFILE
            shift 2
            ;;
        -w|--powershell|--pw)
            MODE="powershell"
            shift
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
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then
    TARGET="${POSITIONAL_ARGS[0]}"
fi

# Determine AWS Region if not specified
if [ -z "$REGION" ]; then
    REGION=$(aws_cli configure get region 2>/dev/null || echo "ap-south-1")
fi

log_info "Discovering Instance ID for target '${TARGET}' in region '${REGION}'..."
INSTANCE_ID=$(get_instance_id "$TARGET" "$REGION" || true)

if [ -z "$INSTANCE_ID" ]; then
    log_error "Could not find a running EC2 instance for target '${TARGET}'."
    exit 1
fi

log_success "Target resolved to Instance ID: ${INSTANCE_ID}"

if [ "$MODE" == "powershell" ]; then
    log_info "Initiating SSM PowerShell session..."
    aws_cli ssm start-session \
        --region "$REGION" \
        --target "$INSTANCE_ID" \
        --document-name AWS-StartPSSession
else
    log_info "Initiating SSM session..."
    aws_cli ssm start-session \
        --region "$REGION" \
        --target "$INSTANCE_ID"
fi
