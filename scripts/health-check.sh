#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - Remote AD Health Check Script
# ==============================================================================
# Executes Active Directory health diagnostics via AWS SSM.
# Sends local script content dynamically or falls back to documented instance path.
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

TARGET="DC01"
REGION=""
CUSTOM_SCRIPT=""
DEFAULT_SCRIPT="${ROOT_DIR}/powershell/common/Test-ADHealth.ps1"
INSTALLED_AUTOMATION_PATH="C:\\Automation\\powershell\\common\\Test-ADHealth.ps1"
LEGACY_BOOTSTRAP_PATH="C:\\bootstrap\\powershell\\common\\Test-ADHealth.ps1"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TARGET]

Executes Active Directory health check diagnostics on Domain Controllers via AWS SSM.

TARGET:
  DC01 (default) or DC02

Options:
  -s, --script SCRIPT_PATH  Path to custom local PowerShell script to upload and execute
  -p, --profile PROFILE     AWS CLI profile to use (or set AWS_PROFILE env var)
  -r, --region REGION       AWS Region (default: derived from AWS CLI config)
  -h, --help                Display this help message and exit

Examples:
  $(basename "$0") DC01
  $(basename "$0") DC02 --profile aws-ad-lab
  $(basename "$0") DC01 --script ./powershell/dc01/Promote-Forest.ps1
EOF
}

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--script)
            CUSTOM_SCRIPT="$2"
            shift 2
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
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then
    TARGET="${POSITIONAL_ARGS[0]}"
fi

if [ -z "$REGION" ]; then
    REGION=$(aws_cli configure get region 2>/dev/null || echo "ap-south-1")
fi

log_info "Discovering Instance ID for '${TARGET}' in region '${REGION}'..."
INSTANCE_ID=$(get_instance_id "$TARGET" "$REGION" || true)

if [ -z "$INSTANCE_ID" ]; then
    log_error "Could not find running instance for '${TARGET}'."
    exit 1
fi

SCRIPT_TO_SEND="${CUSTOM_SCRIPT:-$DEFAULT_SCRIPT}"
COMMAND_ID=""

if [ -f "$SCRIPT_TO_SEND" ]; then
    log_info "Uploading and executing local script '${SCRIPT_TO_SEND}' on ${TARGET} (${INSTANCE_ID})..."
    SCRIPT_JSON=$(jq -sR . "$SCRIPT_TO_SEND")
    PARAMETERS_JSON="{\"commands\":[${SCRIPT_JSON}]}"

    COMMAND_ID=$(aws_cli ssm send-command \
        --region "$REGION" \
        --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunPowerShellScript" \
        --parameters "$PARAMETERS_JSON" \
        --query "Command.CommandId" \
        --output text)
else
    log_warn "Local script file '${SCRIPT_TO_SEND}' not found. Falling back to packaged instance path..."
    FALLBACK_CMD="if (Test-Path '${INSTALLED_AUTOMATION_PATH}') { & '${INSTALLED_AUTOMATION_PATH}' } else { & '${LEGACY_BOOTSTRAP_PATH}' }"
    
    COMMAND_ID=$(aws_cli ssm send-command \
        --region "$REGION" \
        --instance-ids "$INSTANCE_ID" \
        --document-name "AWS-RunPowerShellScript" \
        --parameters "{\"commands\":[\"${FALLBACK_CMD}\"]}" \
        --query "Command.CommandId" \
        --output text)
fi

log_info "SSM Command submitted (ID: ${COMMAND_ID}). Waiting for completion..."

aws_cli ssm wait command-executed \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" 2>/dev/null || true

OUTPUT=$(aws_cli ssm get-command-invocation \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --query "StandardOutputContent" \
    --output text)

ERROR_OUTPUT=$(aws_cli ssm get-command-invocation \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --query "StandardErrorContent" \
    --output text)

echo "=========================================================="
echo "Health Check Diagnostics Output (${TARGET})"
echo "=========================================================="
if [ -n "$OUTPUT" ]; then
    echo "$OUTPUT"
fi

if [ -n "$ERROR_OUTPUT" ] && [ "$ERROR_OUTPUT" != "None" ]; then
    echo -e "${RED}Errors encountered during execution:${NC}"
    echo "$ERROR_OUTPUT"
fi
echo "=========================================================="
