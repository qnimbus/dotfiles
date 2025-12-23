# Repository Operations

Commands for working with GitHub repositories using `gh repo`.

## Quick Reference

- Clone: `gh repo clone <repo>`
- Create: `gh repo create [name]`
- View: `gh repo view [repo]`
- Fork: `gh repo fork [repo]`
- List: `gh repo list [owner]`
- Delete: `gh repo delete [repo]`

## Cloning Repositories

```bash
# Clone a repository
gh repo clone owner/repo

# Clone into a specific directory
gh repo clone owner/repo target-dir

# Clone your own repo (current user)
gh repo clone my-repo
```

## Creating Repositories

```bash
# Interactive create (prompts for details)
gh repo create

# Create with name
gh repo create my-new-repo

# Create with options
gh repo create my-new-repo --public --description "My awesome project"
gh repo create my-new-repo --private --clone

# Create from template
gh repo create my-new-repo --template owner/template-repo

# Create with .gitignore
gh repo create my-new-repo --gitignore Node

# Push current directory to new repo
gh repo create --source=. --public --push
```

**Common flags:**
- `--public` / `--private` / `--internal` - Set visibility
- `--description` - Repository description
- `--clone` - Clone after creation
- `--push` - Push local commits to new repo
- `--source` - Path to local repository (default: `.`)
- `--remote` - Name of the new remote (default: `origin`)
- `--gitignore` - Specify .gitignore template
- `--license` - Specify license template

## Viewing Repository Information

```bash
# View current repository
gh repo view

# View specific repository
gh repo view owner/repo

# View in browser
gh repo view --web
gh repo view owner/repo --web

# Get specific information
gh repo view --json name,description,url,defaultBranchRef
gh repo view owner/repo --json stargazerCount,forkCount
```

**Common --json fields:**
- `name`, `description`, `url`, `sshUrl`, `homepageUrl`
- `createdAt`, `updatedAt`, `pushedAt`
- `stargazerCount`, `forkCount`, `watchers`
- `isPrivate`, `isFork`, `isArchived`
- `defaultBranchRef`, `licenseInfo`, `languages`
- `owner`, `primaryLanguage`

## Forking Repositories

```bash
# Fork a repository
gh repo fork owner/repo

# Fork and clone
gh repo fork owner/repo --clone

# Fork without cloning
gh repo fork owner/repo --clone=false

# Fork with custom remote name
gh repo fork owner/repo --clone --remote-name upstream
```

## Listing Repositories

```bash
# List your repositories
gh repo list

# List another user's repositories
gh repo list username

# List organization repositories
gh repo list orgname

# Limit results
gh repo list --limit 50

# Filter by language
gh repo list --language JavaScript

# Filter by visibility
gh repo list --public
gh repo list --private

# Get specific fields as JSON
gh repo list --json name,url,pushedAt

# Filter by topic
gh repo list --topic machine-learning
```

**Common flags:**
- `--limit` - Maximum repos to list (default: 30)
- `--language` - Filter by language
- `--public` / `--private` - Filter by visibility
- `--source` - Only show non-forks
- `--fork` - Only show forks
- `--archived` - Include archived repos
- `--topic` - Filter by topic

## Deleting Repositories

```bash
# Delete a repository (prompts for confirmation)
gh repo delete owner/repo

# Delete without confirmation
gh repo delete owner/repo --yes
gh repo delete owner/repo --confirm

# Delete current repository
gh repo delete
```

**Warning:** This action is irreversible. Use with caution.

## Syncing Forks

```bash
# Sync fork with upstream
gh repo sync

# Sync specific fork
gh repo sync owner/repo

# Sync specific branch
gh repo sync --branch main
```

## Setting Default Branch

```bash
# View current default branch
gh repo view --json defaultBranchRef

# Set via gh (requires API call)
gh api repos/owner/repo --method PATCH --field default_branch=main
```

## Archive/Unarchive

```bash
# Archive repository
gh repo archive owner/repo

# Unarchive repository
gh repo unarchive owner/repo
```

## Common Patterns

### Check if repository exists
```bash
if gh repo view owner/repo &>/dev/null; then
    echo "Repository exists"
else
    echo "Repository not found"
fi
```

### Get repository URL
```bash
REPO_URL=$(gh repo view --json url --jq '.url')
```

### List all your public repositories
```bash
gh repo list --public --limit 100
```

### Create and push in one command
```bash
# From existing local directory
cd my-project
gh repo create --source=. --public --push
```
