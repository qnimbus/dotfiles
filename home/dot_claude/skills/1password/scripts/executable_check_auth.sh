#!/bin/bash
# Check if the user is authenticated with 1Password CLI
#
# Returns:
#   0 if authenticated
#   1 if not authenticated

set -e

# Try to run a simple op command that requires authentication
if op account list &>/dev/null; then
    echo "✓ Authenticated with 1Password CLI"
    exit 0
else
    echo "✗ Not authenticated with 1Password CLI"
    echo ""
    echo "To authenticate, run:"
    echo "  eval \$(op signin)"
    echo ""
    echo "Or if you haven't signed in before:"
    echo "  op account add"
    exit 1
fi
