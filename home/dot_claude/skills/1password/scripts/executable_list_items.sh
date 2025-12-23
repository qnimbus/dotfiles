#!/bin/bash
# List items from 1Password vaults without displaying secret values
#
# Usage:
#   scripts/list_items.sh [vault-name] [--category <category>]
#
# Arguments:
#   vault-name: (Optional) Name or UUID of vault to list items from
#   --category: (Optional) Filter by category (Login, Password, API Credential, etc.)
#
# Examples:
#   scripts/list_items.sh                          # List all items from all vaults
#   scripts/list_items.sh "Development"            # List items from Development vault
#   scripts/list_items.sh --category "API Credential"  # List only API credentials
#
# SECURITY NOTE: This script only displays metadata (titles, categories)
# It NEVER displays passwords, API keys, or other secret values

set -e

VAULT=""
CATEGORY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        *)
            VAULT="$1"
            shift
            ;;
    esac
done

# Build the command
CMD="op item list --format json"

if [ -n "$VAULT" ]; then
    CMD="$CMD --vault \"$VAULT\""
fi

if [ -n "$CATEGORY" ]; then
    CMD="$CMD --categories \"$CATEGORY\""
fi

# Execute and format output (metadata only, no secrets)
echo "Listing 1Password items (metadata only, secrets hidden):"
echo ""

eval "$CMD" | jq -r '.[] | "[\(.category)] \(.title) (vault: \(.vault.name))"' | sort

echo ""
echo "Note: Secret values are not displayed. Use get_secret.sh to retrieve specific secrets."
