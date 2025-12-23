#!/bin/bash
# Retrieve a secret from 1Password and export it as an environment variable
# WITHOUT displaying the secret value in output
#
# Usage:
#   source scripts/get_secret.sh <item-reference> <field-name> <env-var-name> [vault]
#
# Arguments:
#   item-reference: Name or UUID of the 1Password item
#   field-name: Field to retrieve (e.g., "password", "username", "credential")
#   env-var-name: Environment variable name to export the secret to
#   vault: (Optional) Vault name or UUID
#
# Example:
#   source scripts/get_secret.sh "GitHub API Token" "credential" "GITHUB_TOKEN"
#   source scripts/get_secret.sh "Production DB" "password" "DB_PASSWORD" "Infrastructure"
#
# SECURITY NOTE: This script NEVER echoes or prints the secret value
# The secret is only stored in the specified environment variable

set -e

if [ $# -lt 3 ]; then
    echo "Usage: source $0 <item-reference> <field-name> <env-var-name> [vault]"
    echo ""
    echo "Example:"
    echo "  source $0 \"GitHub API Token\" \"credential\" \"GITHUB_TOKEN\""
    exit 1
fi

ITEM_REF="$1"
FIELD_NAME="$2"
ENV_VAR_NAME="$3"
VAULT="${4:-}"

# Build the op command
if [ -n "$VAULT" ]; then
    OP_CMD="op item get \"$ITEM_REF\" --vault \"$VAULT\" --fields \"$FIELD_NAME\""
else
    OP_CMD="op item get \"$ITEM_REF\" --fields \"$FIELD_NAME\""
fi

# Retrieve the secret (without displaying it)
SECRET_VALUE=$(eval "$OP_CMD" 2>&1)

if [ $? -eq 0 ]; then
    # Export the secret to the environment variable
    export "$ENV_VAR_NAME=$SECRET_VALUE"

    # Confirm success without showing the secret
    echo "✓ Retrieved secret from '$ITEM_REF' (field: $FIELD_NAME)"
    echo "✓ Exported to environment variable: $ENV_VAR_NAME"
    echo ""
    echo "The secret is now available in \$$ENV_VAR_NAME (not displayed for security)"
else
    echo "✗ Failed to retrieve secret: $SECRET_VALUE"
    exit 1
fi
