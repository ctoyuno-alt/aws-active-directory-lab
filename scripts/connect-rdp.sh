#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - SSM RDP Port Forwarding Wrapper Script
# ==============================================================================
# Establish a secure RDP tunnel to DC01/DC02 using AWS SSM Port Forwarding.
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
LOCAL_PORT=""

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TARGET]

Establishes a secure RDP port-forwarding tunnel using AWS SSM Session Manager.

TARGET:
  DC01 (default), DC02, or a specific EC2 Instance ID (e.g. i-0123456789abcdef0)

Options:
  -p, --profile PROFILE   AWS CLI profile to use (or set AWS_PROFILE env var)
  -l, --local-port PORT   Local port to forward to (default: 13389 for DC01, 13390 for DC02)
  -r, --region REGION     AWS Region (default: derived from AWS CLI config)
  -h, --help              Display this help message and exit

Examples:
  $(basename "$0") DC01
  $(basename "$0") DC02 --local-port 13390
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
        -l|--local-port)
            LOCAL_PORT="$2"
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

# Set default local port based on target if not specified
if [ -z "$LOCAL_PORT" ]; then
    if [ "${TARGET^^}" == "DC02" ]; then
        LOCAL_PORT="13390"
    else
        LOCAL_PORT="13389"
    fi
fi

log_info "Establishing secure RDP tunnel via AWS SSM Port Forwarding..."
log_success "Local Port: ${LOCAL_PORT} -> Remote Port: 3389"
log_warn "Keep this terminal open! Connect your RDP client to: localhost:${LOCAL_PORT}"

aws_cli ssm start-session \
    --region "$REGION" \
    --target "$INSTANCE_ID" \
    --document-name AWS-StartPortForwardingSession \
    --parameters "portNumber=3389,localPortNumber=${LOCAL_PORT}"
