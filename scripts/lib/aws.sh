#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - AWS Helper Functions Library
# ==============================================================================
# Centralizes AWS CLI instance lookups and AWS service interactions.
# ==============================================================================

# Guard against multiple sourcing
if [ -n "${_AWS_SH_LOADED:-}" ]; then
    return 0
fi
_AWS_SH_LOADED=1

# ------------------------------------------------------------------------------
# Function: get_instance_id
# Purpose:  Resolves an instance ID given a target (Instance ID, Hostname tag,
#           or Name tag). Handles case-insensitive target matching.
# Arguments:
#   $1 - Target string (e.g. DC01, dc01, DC02, or i-0123456789abcdef0)
#   $2 - (Optional) AWS Region
# Outputs:
#   Instance ID string to stdout if found, empty if not found.
# Return Code:
#   0 if instance found, 1 if not found.
# ------------------------------------------------------------------------------
get_instance_id() {
    local target="${1:-}"
    local region="${2:-}"

    if [ -z "$target" ]; then
        return 1
    fi

    # 1. If target is already an Instance ID format (i-xxxxxxxx), return it directly
    if [[ "$target" =~ ^i-[a-f0-9]+$ ]]; then
        echo "$target"
        return 0
    fi

    # Determine region if not provided
    if [ -z "$region" ]; then
        region=$(aws_cli configure get region 2>/dev/null || echo "ap-south-1")
    fi

    local target_lower="${target,,}"
    local target_upper="${target^^}"

    # 2. Search by Hostname tag (case variants)
    local instance_id
    instance_id=$(aws_cli ec2 describe-instances \
        --region "$region" \
        --filters "Name=tag:Hostname,Values=${target},${target_lower},${target_upper}" "Name=instance-state-name,Values=running" \
        --query "Reservations[].Instances[0].InstanceId" \
        --output text 2>/dev/null || true)

    # 3. Fallback: Search by Name tag pattern (case variants)
    if [ -z "$instance_id" ] || [ "$instance_id" == "None" ]; then
        instance_id=$(aws_cli ec2 describe-instances \
            --region "$region" \
            --filters "Name=tag:Name,Values=*${target}*,*${target_lower}*,*${target_upper}*" "Name=instance-state-name,Values=running" \
            --query "Reservations[].Instances[0].InstanceId" \
            --output text 2>/dev/null || true)
    fi

    if [ -n "$instance_id" ] && [ "$instance_id" != "None" ]; then
        echo "$instance_id"
        return 0
    else
        return 1
    fi
}
