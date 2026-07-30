#!/usr/bin/env bash
# ==============================================================================
# AWS Active Directory Lab - Shared Bash Library
# ==============================================================================
# Contains common variables, terminal colors, logging helper functions, and AWS CLI wrapper.
# Sourced by scripts in scripts/.
# ==============================================================================

# Guard against multiple sourcing
if [ -n "${_COMMON_SH_LOADED:-}" ]; then
    return 0
fi
_COMMON_SH_LOADED=1

# --- Global AWS Profile & Region ---
AWS_PROFILE="${AWS_PROFILE:-}"
if [ -z "$AWS_PROFILE" ]; then
    # Fallback to aws-ad-lab if it exists in local aws profiles
    if aws configure list-profiles 2>/dev/null | grep -q "^aws-ad-lab$"; then
        AWS_PROFILE="aws-ad-lab"
    fi
fi

# --- Terminal Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Shared Logging Helper Functions ---
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# --- AWS CLI Wrapper ---
# Executes aws command with --profile if AWS_PROFILE is set
aws_cli() {
    if [ -n "${AWS_PROFILE:-}" ]; then
        aws --profile "$AWS_PROFILE" "$@"
    else
        aws "$@"
    fi
}

# --- Auto-source Sub-libraries ---
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" 2>/dev/null && pwd || echo "")"

if [ -n "$_LIB_DIR" ] && [ -f "${_LIB_DIR}/aws.sh" ]; then
    source "${_LIB_DIR}/aws.sh"
fi
