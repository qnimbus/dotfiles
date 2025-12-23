---
name: 1password
description: Securely retrieve secrets from 1Password using the 'op' CLI tool without displaying sensitive information. Use when working with API keys, tokens, passwords, SSH keys, database credentials, or any secrets stored in 1Password. All secret values are stored only in environment variables and NEVER displayed in output or context.
---

# 1Password Secure Secret Management

This skill enables secure retrieval and management of secrets from 1Password using the `op` CLI tool with a critical security constraint: **secrets are NEVER displayed in output or loaded into context**. All sensitive data is stored exclusively in environment variables.

## Security Principles

**CRITICAL RULES - NEVER VIOLATE THESE:**

1. **Never display secrets**: Do NOT use `echo`, `print`, `cat`, or any command that would output secret values
2. **Never load secrets into context**: Secret values must NEVER appear in Claude's context window
3. **Only use environment variables**: All secrets must be stored in environment variables, never in files or logs
4. **Use provided scripts**: Always use the bundled scripts which are designed to prevent secret exposure
5. **Verify before displaying**: Before showing any command output, verify it contains no secret values

## Prerequisites

Users must have:
- 1Password CLI (`op`) installed
- Authenticated 1Password session (run `eval $(op signin)` before using this skill)

## Core Operations

### 1. Check Authentication Status

Before performing any operations, verify authentication:

```bash
scripts/check_auth.sh
```

If not authenticated, the script will display instructions for signing in.

### 2. List Items and Vaults (Safe - No Secrets)

List available items to find what you need:

```bash
# List all items (shows titles and categories only, NO secrets)
scripts/list_items.sh

# List items from specific vault
scripts/list_items.sh "Development"

# List items by category
scripts/list_items.sh --category "API Credential"
```

**Output safety**: This command only displays metadata (titles, categories, vault names). No secret values are shown.

### 3. Retrieve Secrets to Environment Variables

Retrieve a secret and export it to an environment variable:

```bash
# Basic usage
source scripts/get_secret.sh "<item-name>" "<field-name>" "<ENV_VAR_NAME>"

# With vault specification
source scripts/get_secret.sh "<item-name>" "<field-name>" "<ENV_VAR_NAME>" "<vault-name>"
```

**Examples:**

```bash
# Get GitHub API token
source scripts/get_secret.sh "GitHub API Token" "credential" "GITHUB_TOKEN"

# Get database password from Infrastructure vault
source scripts/get_secret.sh "Production DB" "password" "DB_PASSWORD" "Infrastructure"

# Get SSH private key
source scripts/get_secret.sh "Production Server SSH" "private key" "SSH_PRIVATE_KEY"
```

**Important**: The script confirms retrieval without showing the secret:
```
✓ Retrieved secret from 'GitHub API Token' (field: credential)
✓ Exported to environment variable: GITHUB_TOKEN

The secret is now available in $GITHUB_TOKEN (not displayed for security)
```

### 4. Using Retrieved Secrets

Once secrets are in environment variables, they can be used in commands:

```bash
# Use API token
curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user

# Use database credentials
psql "postgresql://admin:$DB_PASSWORD@$DB_HOST/mydb"

# Use in Python script
python script.py  # Script accesses os.environ['GITHUB_TOKEN']
```

**Security note**: The secret value is never displayed, only used programmatically.

## Common Workflows

### Workflow: Set Up Development Environment

```bash
# 1. Check authentication
scripts/check_auth.sh

# 2. List available API credentials
scripts/list_items.sh --category "API Credential"

# 3. Retrieve needed secrets
source scripts/get_secret.sh "GitHub API Token" "credential" "GITHUB_TOKEN"
source scripts/get_secret.sh "Stripe API Key" "credential" "STRIPE_API_KEY"
source scripts/get_secret.sh "AWS Access Key" "access key id" "AWS_ACCESS_KEY_ID"

# 4. Use in development
npm run dev  # App reads from environment variables
```

### Workflow: Connect to Database

```bash
# 1. Check authentication
scripts/check_auth.sh

# 2. Find database item
scripts/list_items.sh "Infrastructure"

# 3. Retrieve all connection details
source scripts/get_secret.sh "Production DB" "hostname" "DB_HOST" "Infrastructure"
source scripts/get_secret.sh "Production DB" "port" "DB_PORT" "Infrastructure"
source scripts/get_secret.sh "Production DB" "username" "DB_USER" "Infrastructure"
source scripts/get_secret.sh "Production DB" "password" "DB_PASSWORD" "Infrastructure"

# 4. Connect
psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/mydb"
```

### Workflow: Use SSH Key

```bash
# 1. Retrieve SSH private key
source scripts/get_secret.sh "Production Server SSH" "private key" "SSH_PRIVATE_KEY"

# 2. Write to temporary file with proper permissions
echo "$SSH_PRIVATE_KEY" > /tmp/ssh_key
chmod 600 /tmp/ssh_key

# 3. Use for SSH connection
ssh -i /tmp/ssh_key user@server.example.com

# 4. Clean up
rm /tmp/ssh_key
unset SSH_PRIVATE_KEY
```

## Field Names Reference

Common field names used in 1Password items:

| Field Name | Used In | Description |
|-----------|---------|-------------|
| `password` | Login items | Password field |
| `username` | Login items | Username field |
| `credential` | API Credential items | API key or token |
| `notesPlain` | Secure Notes | Plain text notes |
| `private key` | SSH Key items | SSH private key |
| `public key` | SSH Key items | SSH public key |
| `hostname` | Database/Server | Server hostname |
| `port` | Database/Server | Port number |
| `database` | Database items | Database name |

For custom fields, use the exact label as it appears in 1Password.

To see all available fields for an item (without exposing secrets):
```bash
op item get "ItemName" --format json | jq '.fields[] | {label, type}'
```

## Item Categories

When listing items, you can filter by category:
- `Login` - Website logins, application credentials
- `API Credential` - API keys, tokens, credentials
- `Database` - Database connection information
- `Server` - Server access credentials
- `SSH Key` - SSH private/public keys
- `Password` - Standalone passwords
- `Secure Note` - Encrypted text notes

## Reference Documentation

For detailed information about the 1Password CLI:
- See [references/op_cli_reference.md](references/op_cli_reference.md) for comprehensive `op` command documentation
- Includes field types, categories, safe commands, and security best practices

## Security Best Practices

1. **Clean up after use**: Unset environment variables when done:
   ```bash
   unset GITHUB_TOKEN DB_PASSWORD SSH_PRIVATE_KEY
   ```

2. **Minimize exposure time**: Retrieve secrets only when needed, unset immediately after use

3. **Avoid temporary files**: Prefer environment variables over files when possible

4. **Check authentication first**: Always verify authentication before attempting secret retrieval

5. **Use specific fields**: Request only the specific field needed, not entire items

6. **Never log secrets**: Secrets in env vars won't appear in shell history (unlike echoed values)

## Error Handling

If scripts fail, common issues and solutions:

**"You are not currently signed in"**
- Run: `eval $(op signin)`

**"Item not found"**
- Verify item name/UUID is correct
- Check you have access to the vault containing the item
- Use `scripts/list_items.sh` to see available items

**"More than one item matches"**
- Multiple items have the same name
- Solution: Specify vault name or use item UUID

**"Field not found"**
- Check field name spelling
- Use `op item get "ItemName" --format json | jq '.fields[] | {label, type}'` to see available fields

## Advanced Usage

### Using with Scripts

When using secrets in Python/Node.js scripts:

```python
import os

# Secret was retrieved to environment variable
github_token = os.environ.get('GITHUB_TOKEN')
if not github_token:
    raise ValueError("GITHUB_TOKEN not found in environment")

# Use the token (never print it)
headers = {'Authorization': f'Bearer {github_token}'}
```

### Multiple Secrets in One Session

Retrieve multiple secrets efficiently:

```bash
# Set up all needed secrets
source scripts/get_secret.sh "GitHub Token" "credential" "GITHUB_TOKEN"
source scripts/get_secret.sh "NPM Token" "credential" "NPM_TOKEN"
source scripts/get_secret.sh "Docker Hub" "password" "DOCKER_PASSWORD"

# Run deployment script that uses all three
./deploy.sh

# Clean up all at once
unset GITHUB_TOKEN NPM_TOKEN DOCKER_PASSWORD
```

### Vault Organization

For teams with multiple vaults:
- **Development**: Development API keys, test credentials
- **Production**: Production secrets, critical access keys
- **Infrastructure**: Server access, database credentials
- **Shared**: Team-shared passwords, common tools

Specify vault when retrieving to avoid ambiguity:
```bash
source scripts/get_secret.sh "DB Password" "password" "DB_PASS" "Production"
```
