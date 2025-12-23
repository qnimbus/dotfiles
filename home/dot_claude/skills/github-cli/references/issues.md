# Issue Management

Commands for working with GitHub issues using `gh issue`.

## Quick Reference

- Create: `gh issue create`
- List: `gh issue list`
- View: `gh issue view <number>`
- Close: `gh issue close <number>`
- Reopen: `gh issue reopen <number>`
- Comment: `gh issue comment <number>`
- Edit: `gh issue edit <number>`
- Status: `gh issue status`

## Creating Issues

```bash
# Interactive create (opens editor)
gh issue create

# Create with title and body
gh issue create --title "Bug: Login fails" --body "Users cannot log in"

# Create with title only (prompts for body)
gh issue create --title "Feature request"

# Create from file
gh issue create --title "Bug report" --body-file bug-details.md

# Create with labels
gh issue create --title "Bug fix" --label bug --label priority-high

# Create with assignee
gh issue create --title "Task" --assignee username
gh issue create --title "Task" --assignee @me

# Create with milestone
gh issue create --title "Feature" --milestone "v1.0"

# Create with project
gh issue create --title "Task" --project "Sprint 1"

# Create in specific repo
gh issue create --repo owner/repo --title "Issue title"

# Open in browser after creation
gh issue create --web
```

**Common flags:**
- `--title` - Issue title
- `--body` - Issue body text
- `--body-file` - Read body from file
- `--label` - Add labels (can be repeated)
- `--assignee` - Assign users (can be repeated)
- `--milestone` - Set milestone
- `--project` - Add to project
- `--web` - Open in browser

## Listing Issues

```bash
# List issues in current repo
gh issue list

# List with filters
gh issue list --state open
gh issue list --state closed
gh issue list --state all

# Filter by label
gh issue list --label bug
gh issue list --label "needs triage"

# Filter by assignee
gh issue list --assignee username
gh issue list --assignee @me

# Filter by author
gh issue list --author username

# Filter by milestone
gh issue list --milestone "v1.0"

# Limit results
gh issue list --limit 50

# Search issues
gh issue list --search "login error"
gh issue list --search "is:open label:bug"

# Get JSON output
gh issue list --json number,title,state,labels

# List in specific repo
gh issue list --repo owner/repo
```

**Common --json fields:**
- `number`, `title`, `body`, `state`, `url`
- `author`, `assignees`, `labels`, `milestone`
- `createdAt`, `updatedAt`, `closedAt`
- `comments`, `reactions`

## Viewing Issues

```bash
# View issue details
gh issue view 42

# View in browser
gh issue view 42 --web

# View with comments
gh issue view 42 --comments

# Get JSON output
gh issue view 42 --json number,title,body,state,labels,assignees

# View from specific repo
gh issue view 42 --repo owner/repo
```

## Closing Issues

```bash
# Close an issue
gh issue close 42

# Close with comment
gh issue close 42 --comment "Fixed in PR #45"

# Close as not planned
gh issue close 42 --reason "not planned"

# Close as completed (default)
gh issue close 42 --reason completed
```

**Close reasons:**
- `completed` - Issue was completed (default)
- `"not planned"` - Issue won't be worked on

## Reopening Issues

```bash
# Reopen a closed issue
gh issue reopen 42

# Reopen with comment
gh issue reopen 42 --comment "Still experiencing this"
```

## Commenting on Issues

```bash
# Add comment interactively (opens editor)
gh issue comment 42

# Add comment with text
gh issue comment 42 --body "I can reproduce this"

# Add comment from file
gh issue comment 42 --body-file response.md

# Edit last comment
gh issue comment 42 --edit-last

# Open in browser to comment
gh issue comment 42 --web
```

## Editing Issues

```bash
# Edit title
gh issue edit 42 --title "New title"

# Edit body
gh issue edit 42 --body "Updated description"

# Add labels
gh issue edit 42 --add-label bug,priority-high

# Remove labels
gh issue edit 42 --remove-label needs-info

# Add assignees
gh issue edit 42 --add-assignee user1,user2

# Remove assignees
gh issue edit 42 --remove-assignee user1

# Change milestone
gh issue edit 42 --milestone "v2.0"

# Remove milestone
gh issue edit 42 --milestone ""

# Add to project
gh issue edit 42 --add-project "Project Name"

# Remove from project
gh issue edit 42 --remove-project "Project Name"
```

## Issue Status

```bash
# Show issue status overview
gh issue status

# Shows:
# - Issues assigned to you
# - Issues you created
# - Issues mentioning you
```

## Transferring Issues

```bash
# Transfer to another repository
gh issue transfer 42 owner/other-repo
```

## Pinning Issues

```bash
# Pin issue (via API)
gh api graphql -f query='
  mutation {
    pinIssue(input: {issueId: "ISSUE_ID"}) {
      issue {
        title
      }
    }
  }
'
```

## Common Patterns

### Create issue from template
```bash
# If .github/ISSUE_TEMPLATE/ exists
gh issue create --template bug_report.md
```

### Bulk close issues
```bash
# Close all issues with specific label
gh issue list --label "duplicate" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --reason "not planned"
```

### Find stale issues
```bash
# List issues not updated in 30 days
gh issue list --search "is:open updated:<$(date -d '30 days ago' +%Y-%m-%d)"
```

### Auto-assign issue to yourself
```bash
gh issue create --title "My task" --assignee @me
```

### Get issue count
```bash
# Count open issues
gh issue list --state open --limit 1000 --json number | jq 'length'
```

### Link issues to PRs in comments
```bash
gh issue comment 42 --body "Fixed by #45"
```

## Issue Template Detection

When using `gh issue create` without flags, GitHub CLI will:
1. Check for issue templates in `.github/ISSUE_TEMPLATE/`
2. Prompt you to select a template if multiple exist
3. Pre-fill the issue with template content
