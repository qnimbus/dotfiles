---
name: github-cli
description: Interact with GitHub using the 'gh' command-line tool for repository operations, issue management, pull requests, GitHub Actions workflows, releases, and gists. Use when working with GitHub repositories, when the user mentions 'gh' commands, GitHub operations, or requests like creating issues, managing PRs, viewing workflows, creating releases, or working with gists.
---

# GitHub CLI (gh) Operations

Interact with GitHub using the `gh` command-line tool for comprehensive repository and project management.

## Prerequisites and Authentication

**IMPORTANT:** The GitHub CLI requires authentication before use. The user must authenticate themselves.

### Check Authentication Status

Always verify authentication before attempting GitHub operations:

```bash
gh auth status
```

If not authenticated, the output will indicate login is required.

### User Authentication Required

If `gh auth status` shows the user is not logged in, inform them they need to authenticate:

**Tell the user:**
> "You need to authenticate with GitHub CLI first. Please run: `gh auth login` and follow the prompts to authenticate. I cannot handle authentication for security reasons - you'll need to complete this step yourself."

**Do not attempt to:**
- Run `gh auth login` directly
- Handle credentials or tokens
- Store authentication information

The user must complete authentication in their own terminal session.

### Verifying Repository Context

Many `gh` commands work in repository context. Verify you're in a git repository:

```bash
# Check if in a git repository
git rev-parse --is-inside-work-tree 2>/dev/null
```

If not in a repository and repo context is needed, either:
- Navigate to the repository directory, or
- Use `--repo owner/repo` flag to specify the target repository

## Available Operations

The GitHub CLI provides commands for six main domains:

1. **Repository Operations** - Clone, create, view, fork, list repositories
2. **Issue Management** - Create, list, view, edit, comment on issues
3. **Pull Requests** - Create, review, merge, manage PRs
4. **GitHub Actions** - View workflows, trigger runs, check status
5. **Release Management** - Create, publish, manage releases
6. **Gist Operations** - Create, share, manage code snippets

## Domain-Specific Command References

For detailed command syntax and examples, consult the appropriate reference file:

### Repository Operations
**See [references/repos.md](references/repos.md)**

Common commands:
- Clone: `gh repo clone owner/repo`
- Create: `gh repo create [name]`
- View: `gh repo view [repo]`
- List: `gh repo list [owner]`

Use for: Cloning repositories, creating new repos, viewing repo info, managing forks.

### Issue Management
**See [references/issues.md](references/issues.md)**

Common commands:
- Create: `gh issue create --title "Title" --body "Description"`
- List: `gh issue list`
- View: `gh issue view <number>`
- Close: `gh issue close <number>`

Use for: Creating and tracking issues, adding labels, assigning users, managing milestones.

### Pull Requests
**See [references/pull-requests.md](references/pull-requests.md)**

Common commands:
- Create: `gh pr create --title "Title" --body "Description"`
- List: `gh pr list`
- View: `gh pr view <number>`
- Checkout: `gh pr checkout <number>`
- Merge: `gh pr merge <number>`
- Review: `gh pr review <number> --approve`

Use for: Creating PRs, reviewing code, managing merge workflow, checking CI status.

### GitHub Actions Workflows
**See [references/workflows.md](references/workflows.md)**

Common commands:
- List workflows: `gh workflow list`
- Run workflow: `gh workflow run <workflow>`
- View runs: `gh run list`
- Watch run: `gh run watch <run-id>`
- View checks: `gh pr checks`

Use for: Triggering workflows, monitoring CI/CD, viewing build status, downloading artifacts.

### Release Management
**See [references/releases.md](references/releases.md)**

Common commands:
- Create: `gh release create <tag> --title "Title" --notes "Notes"`
- List: `gh release list`
- View: `gh release view <tag>`
- Download: `gh release download <tag>`
- Upload: `gh release upload <tag> <files>`

Use for: Creating releases, publishing versions, managing release assets, downloading binaries.

### Gist Operations
**See [references/gists.md](references/gists.md)**

Common commands:
- Create: `gh gist create <file>`
- List: `gh gist list`
- View: `gh gist view <gist-id>`
- Edit: `gh gist edit <gist-id>`

Use for: Sharing code snippets, creating quick pastes, managing gists.

## Common Workflows

### Creating an Issue from Bug Report

```bash
gh issue create \
  --title "Bug: Description" \
  --body "Steps to reproduce..." \
  --label bug \
  --assignee @me
```

### Creating a Pull Request

```bash
# From current branch
gh pr create \
  --title "Feature: Add new capability" \
  --body "This PR adds..." \
  --reviewer username

# Or use commit messages
gh pr create --fill
```

### Checking CI/CD Status

```bash
# For current PR
gh pr checks

# Watch workflow run
gh run watch <run-id>
```

### Creating a Release

```bash
# Create release with auto-generated notes
gh release create v1.0.0 \
  --title "Version 1.0.0" \
  --generate-notes \
  dist/*.zip
```

### Quick Code Sharing

```bash
# Create public gist from file
gh gist create script.sh --public --desc "Useful script"
```

## Getting Help

For any `gh` command, use the `--help` flag:

```bash
gh --help
gh repo --help
gh issue create --help
```

## Working with JSON Output

Many commands support `--json` for programmatic use:

```bash
# Get specific fields
gh repo view --json name,url,stargazerCount

# Parse with jq
gh issue list --json number,title | jq '.[] | select(.title | contains("bug"))'

# Use in scripts
REPO_URL=$(gh repo view --json url --jq '.url')
```

## Repository Context

Some commands require repository context:

```bash
# Explicitly specify repository
gh issue list --repo owner/repo
gh pr create --repo owner/repo

# Or run from within the repository directory
cd /path/to/repo
gh issue list  # Uses current repo
```

## Error Handling

If a `gh` command fails:

1. Check authentication: `gh auth status`
2. Verify repository context: `git remote -v`
3. Check permissions: Ensure you have access to the repository
4. Review error message for specific issues
5. Use `--help` to verify command syntax

Common errors:
- **Not authenticated**: User needs to run `gh auth login`
- **Not in a repository**: Navigate to repo or use `--repo` flag
- **No permission**: User lacks access to the repository or organization
- **Resource not found**: Issue/PR/Release doesn't exist or wrong repository

## Best Practices

1. **Always verify authentication** before attempting operations
2. **Use `--json` output** for scripting and automation
3. **Specify `--repo`** when working with multiple repositories
4. **Use `--help`** to discover command options
5. **Check status first** with commands like `gh pr status` or `gh issue status`
6. **Use `--web`** flag to open resources in browser when needed
7. **Leverage `--fill`** for PR creation to use commit messages
8. **Use `--draft`** for PRs/releases that aren't ready for review

## Advanced Usage

### Working with Multiple Accounts

```bash
# Check which account is active
gh auth status

# Switch accounts
gh auth switch
```

### Using GitHub API Directly

```bash
# For operations not covered by gh commands
gh api repos/owner/repo/issues

# With POST data
gh api repos/owner/repo/issues --method POST \
  --field title="Issue title" \
  --field body="Issue body"
```

### Automation and Scripting

Combine `gh` with other tools for powerful workflows:

```bash
# Create issue for each failed test
while read test; do
  gh issue create --title "Fix: $test" --label "test-failure"
done < failed-tests.txt

# Auto-merge PRs that pass CI
for pr in $(gh pr list --json number --jq '.[].number'); do
  if gh pr checks $pr | grep -q "All checks"; then
    gh pr merge $pr --auto --squash
  fi
done
```
