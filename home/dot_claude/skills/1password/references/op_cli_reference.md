# 1Password CLI Reference

This document provides reference information for working with the 1Password CLI (`op`) in a secure manner.

## Authentication

Before using the 1Password CLI, users must authenticate:

```bash
# First time setup
op account add

# Sign in to existing account
eval $(op signin)
```

## Item References

Items can be referenced by:
- **Name**: `"GitHub API Token"`
- **UUID**: `"kp2td65r4wbuhkpz56xfq5e2b4"`

For items with duplicate names, use UUID or specify the vault.

## Field Types

Common field types in 1Password items:

| Field Type | Description | Common In |
|-----------|-------------|-----------|
| `password` | Password field | Login items |
| `username` | Username field | Login items |
| `credential` | API key or token | API Credential items |
| `notesPlain` | Secure notes | Secure Note items |
| `database` | Database name | Database items |
| `hostname` | Server/host | Server, Database items |
| `port` | Port number | Server, Database items |

### Custom Fields

Items can have custom fields. Reference them by label:
- `op item get "MyItem" --fields "My Custom Field"`

## Categories

Common 1Password item categories:
- `Login` - Website logins, application credentials
- `Password` - Standalone passwords
- `API Credential` - API keys, tokens, credentials
- `Database` - Database connection information
- `Server` - Server access credentials
- `SSH Key` - SSH private keys
- `Secure Note` - Encrypted text notes
- `Document` - File attachments

## Safe Commands (Read-Only, No Secrets Displayed)

These commands display metadata without revealing secrets:

```bash
# List all vaults
op vault list

# List items (shows titles and categories only)
op item list
op item list --vault "Development"
op item list --categories "API Credential"

# Get item metadata (no secret fields)
op item get "MyItem" --format json | jq 'del(.fields[] | select(.type == "concealed"))'
```

## Secret Retrieval Commands

**CRITICAL**: These commands output secrets and must NEVER have their output displayed:

```bash
# Get specific field (OUTPUTS SECRET - DO NOT ECHO)
op item get "MyItem" --fields password

# Get entire item with secrets (OUTPUTS SECRETS - DO NOT ECHO)
op item get "MyItem" --format json
```

### Safe Usage Pattern

Always redirect secret output to environment variables, never to stdout:

```bash
# CORRECT: Store in variable without displaying
export API_KEY=$(op item get "GitHub Token" --fields credential)

# INCORRECT: Never echo or print secrets
echo $(op item get "GitHub Token" --fields credential)  # DON'T DO THIS
```

## Common Operations

### Retrieve API Token
```bash
# Get API token and export to env var (using provided script)
source scripts/get_secret.sh "GitHub API Token" "credential" "GITHUB_TOKEN"

# Now use it in your code
curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user
```

### Retrieve Database Credentials
```bash
# Get database password
source scripts/get_secret.sh "Production DB" "password" "DB_PASSWORD" "Infrastructure"

# Get database hostname
source scripts/get_secret.sh "Production DB" "hostname" "DB_HOST" "Infrastructure"

# Use in connection
psql "postgresql://user:$DB_PASSWORD@$DB_HOST/mydb"
```

### Retrieve SSH Key
```bash
# Get SSH private key
source scripts/get_secret.sh "Production Server SSH" "private key" "SSH_PRIVATE_KEY"

# Write to temp file (be careful with permissions)
echo "$SSH_PRIVATE_KEY" > /tmp/ssh_key
chmod 600 /tmp/ssh_key
ssh -i /tmp/ssh_key user@server
```

## Security Best Practices

1. **Never echo secrets**: Don't use `echo`, `cat`, or print commands with secret values
2. **Use environment variables**: Store secrets in env vars, not files (when possible)
3. **Clean up after use**: Unset environment variables when done:
   ```bash
   unset GITHUB_TOKEN
   unset DB_PASSWORD
   ```
4. **Check authentication**: Always verify `op` authentication status before operations
5. **Use specific fields**: Request only the specific field needed, not entire items
6. **Avoid logs**: Secrets in env vars won't appear in shell history, but echoed values will

## Error Handling

Common errors and solutions:

```bash
# "You are not currently signed in"
# Solution: Run eval $(op signin)

# "Item not found"
# Solution: Check item name/UUID, verify vault access

# "More than one item matches"
# Solution: Use UUID or specify vault name

# "Field not found"
# Solution: Check field name, use op item get "ItemName" --format json to see available fields
```
