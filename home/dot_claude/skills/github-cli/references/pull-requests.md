# Pull Request Operations

Commands for working with GitHub pull requests using `gh pr`.

## Quick Reference

- Create: `gh pr create`
- List: `gh pr list`
- View: `gh pr view <number>`
- Checkout: `gh pr checkout <number>`
- Status: `gh pr status`
- Merge: `gh pr merge <number>`
- Close: `gh pr close <number>`
- Reopen: `gh pr reopen <number>`
- Review: `gh pr review <number>`
- Checks: `gh pr checks`
- Diff: `gh pr diff <number>`

## Creating Pull Requests

```bash
# Interactive create (prompts for details)
gh pr create

# Create with title and body
gh pr create --title "Fix login bug" --body "Fixes issue #42"

# Create from file
gh pr create --title "Feature" --body-file description.md

# Create as draft
gh pr create --draft

# Create and set reviewers
gh pr create --reviewer user1,user2
gh pr create --reviewer team-name

# Create with labels
gh pr create --label bug,priority-high

# Create with assignees
gh pr create --assignee @me

# Create with milestone
gh pr create --milestone "v1.0"

# Create with project
gh pr create --project "Sprint 1"

# Create to specific base branch
gh pr create --base develop

# Create from specific head branch
gh pr create --head feature-branch

# Fill from commit messages
gh pr create --fill

# Open in browser
gh pr create --web

# Create in specific repo
gh pr create --repo owner/repo
```

**Common flags:**
- `--title` - PR title
- `--body` - PR description
- `--body-file` - Read description from file
- `--draft` - Create as draft PR
- `--base` - Target branch (default: default branch)
- `--head` - Source branch (default: current branch)
- `--reviewer` - Request reviewers
- `--assignee` - Assign users
- `--label` - Add labels
- `--milestone` - Set milestone
- `--project` - Add to project
- `--fill` - Use commits for title and body
- `--web` - Open in browser

## Listing Pull Requests

```bash
# List open PRs
gh pr list

# List all PRs (including closed)
gh pr list --state all
gh pr list --state closed
gh pr list --state merged

# Filter by label
gh pr list --label bug

# Filter by assignee
gh pr list --assignee username
gh pr list --assignee @me

# Filter by author
gh pr list --author username

# Filter by reviewer
gh pr list --search "review-requested:username"

# Filter by base branch
gh pr list --base main

# Filter by head branch
gh pr list --head feature-branch

# Limit results
gh pr list --limit 50

# Search PRs
gh pr list --search "login fix"
gh pr list --search "is:open author:@me"

# Get JSON output
gh pr list --json number,title,state,headRefName,baseRefName

# List in specific repo
gh pr list --repo owner/repo
```

**Common --json fields:**
- `number`, `title`, `body`, `state`, `url`
- `author`, `assignees`, `reviewers`, `labels`
- `headRefName`, `baseRefName`, `mergeCommit`
- `createdAt`, `updatedAt`, `mergedAt`, `closedAt`
- `isDraft`, `mergeable`, `merged`
- `additions`, `deletions`, `changedFiles`

## Viewing Pull Requests

```bash
# View PR details
gh pr view 42

# View in browser
gh pr view 42 --web

# View with comments
gh pr view 42 --comments

# Get JSON output
gh pr view 42 --json number,title,body,state,reviews,statusCheckRollup

# View diff
gh pr view 42 --diff

# View from specific repo
gh pr view 42 --repo owner/repo
```

## Checking Out Pull Requests

```bash
# Check out PR branch locally
gh pr checkout 42

# Check out by branch name
gh pr checkout feature-branch

# Force checkout
gh pr checkout 42 --force

# Checkout from specific repo
gh pr checkout 42 --repo owner/repo
```

## Pull Request Status

```bash
# Show status of relevant PRs
gh pr status

# Shows:
# - PRs assigned to review
# - PRs you created
# - PRs mentioning you
```

## Merging Pull Requests

```bash
# Merge PR (interactive, prompts for merge strategy)
gh pr merge 42

# Merge with specific strategy
gh pr merge 42 --merge      # Create merge commit
gh pr merge 42 --squash     # Squash and merge
gh pr merge 42 --rebase     # Rebase and merge

# Auto-merge (merge when checks pass)
gh pr merge 42 --auto --squash

# Delete branch after merge
gh pr merge 42 --delete-branch

# Merge with custom commit message
gh pr merge 42 --squash --body "Custom merge message"

# Admin merge (bypass protections, use carefully)
gh pr merge 42 --admin

# Disable auto-merge
gh pr merge 42 --disable-auto
```

**Merge strategies:**
- `--merge` - Create a merge commit
- `--squash` - Squash commits into one
- `--rebase` - Rebase commits onto base branch

## Closing Pull Requests

```bash
# Close PR without merging
gh pr close 42

# Close with comment
gh pr close 42 --comment "Won't fix"

# Delete branch when closing
gh pr close 42 --delete-branch
```

## Reopening Pull Requests

```bash
# Reopen a closed PR
gh pr reopen 42

# Reopen with comment
gh pr reopen 42 --comment "Reopening after discussion"
```

## Reviewing Pull Requests

```bash
# Approve PR
gh pr review 42 --approve

# Request changes
gh pr review 42 --request-changes --body "Please fix the tests"

# Comment without approval
gh pr review 42 --comment --body "Looks good overall"

# Review interactively (opens editor)
gh pr review 42

# Review from file
gh pr review 42 --approve --body-file review-comments.md
```

**Review actions:**
- `--approve` - Approve the PR
- `--request-changes` - Request changes
- `--comment` - Comment without approval status

## Checking PR Status

```bash
# View CI/CD checks
gh pr checks

# View checks for specific PR
gh pr checks 42

# Watch checks in real-time
gh pr checks 42 --watch

# View checks from specific repo
gh pr checks 42 --repo owner/repo
```

## Viewing PR Diff

```bash
# View diff of current PR branch
gh pr diff

# View diff of specific PR
gh pr diff 42

# View diff with color
gh pr diff 42 --color always

# View specific file's diff
gh pr diff 42 -- path/to/file.js
```

## Editing Pull Requests

```bash
# Edit title
gh pr edit 42 --title "New title"

# Edit body
gh pr edit 42 --body "Updated description"

# Convert to/from draft
gh pr edit 42 --add-draft      # Mark as draft
gh pr edit 42 --remove-draft   # Ready for review

# Add reviewers
gh pr edit 42 --add-reviewer user1,user2

# Remove reviewers
gh pr edit 42 --remove-reviewer user1

# Add labels
gh pr edit 42 --add-label bug,priority-high

# Remove labels
gh pr edit 42 --remove-label needs-review

# Add assignees
gh pr edit 42 --add-assignee user1,user2

# Remove assignees
gh pr edit 42 --remove-assignee user1

# Change base branch
gh pr edit 42 --base develop

# Change milestone
gh pr edit 42 --milestone "v2.0"

# Add to project
gh pr edit 42 --add-project "Project Name"
```

## Commenting on Pull Requests

```bash
# Add comment (opens editor)
gh pr comment 42

# Add comment with text
gh pr comment 42 --body "Great work!"

# Add comment from file
gh pr comment 42 --body-file comment.md

# Edit last comment
gh pr comment 42 --edit-last

# Open in browser to comment
gh pr comment 42 --web
```

## PR Ready for Review

```bash
# Mark draft PR as ready for review
gh pr ready 42

# Via edit command
gh pr edit 42 --remove-draft
```

## Common Patterns

### Create PR for current branch
```bash
# Quick PR creation from current branch
gh pr create --fill
```

### Auto-merge when tests pass
```bash
gh pr create --title "Feature" --body "Description" --fill
gh pr merge --auto --squash --delete-branch
```

### Request review from team
```bash
gh pr create --reviewer team-name
```

### Check if PR can be merged
```bash
gh pr view 42 --json mergeable,mergeStateStatus
```

### Get PR URL
```bash
PR_URL=$(gh pr view 42 --json url --jq '.url')
```

### List PRs awaiting your review
```bash
gh pr list --search "is:open review-requested:@me"
```

### View failed checks
```bash
gh pr checks 42 | grep -i fail
```

### Link PR to issue
```bash
gh pr create --title "Fix bug" --body "Closes #42"
# In body text: "Fixes #42", "Closes #42", "Resolves #42"
```

### Squash merge with custom message
```bash
gh pr merge 42 --squash --subject "feat: add new feature" --body "Detailed description"
```

### Check review status
```bash
gh pr view 42 --json reviewDecision
# Returns: APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED, etc.
```

## Pull Request Templates

When using `gh pr create` without flags, GitHub CLI will:
1. Check for PR templates in `.github/PULL_REQUEST_TEMPLATE/` or `.github/pull_request_template.md`
2. Pre-fill the PR description with template content
3. Use commit messages if `--fill` is specified
