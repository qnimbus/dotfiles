# GitHub Actions Workflows

Commands for working with GitHub Actions workflows using `gh workflow` and `gh run`.

## Quick Reference

**Workflows:**
- List: `gh workflow list`
- View: `gh workflow view <workflow>`
- Run: `gh workflow run <workflow>`
- Enable: `gh workflow enable <workflow>`
- Disable: `gh workflow disable <workflow>`

**Workflow Runs:**
- List: `gh run list`
- View: `gh run view <run-id>`
- Watch: `gh run watch <run-id>`
- Rerun: `gh run rerun <run-id>`
- Cancel: `gh run cancel <run-id>`
- Download: `gh run download <run-id>`

## Listing Workflows

```bash
# List all workflows
gh workflow list

# List with more details
gh workflow list --all

# Get JSON output
gh workflow list --json name,path,state,id

# List in specific repo
gh workflow list --repo owner/repo
```

## Viewing Workflow Details

```bash
# View workflow by name or ID
gh workflow view "CI"
gh workflow view ci.yml
gh workflow view 12345

# View in browser
gh workflow view "CI" --web

# View specific ref (branch/tag)
gh workflow view "CI" --ref main

# Get YAML content
gh workflow view "CI" --yaml

# Get JSON output
gh workflow view "CI" --json name,path,state,id
```

## Running Workflows

```bash
# Run workflow (if workflow_dispatch event is configured)
gh workflow run "CI"
gh workflow run ci.yml

# Run on specific branch
gh workflow run "Deploy" --ref production

# Run with inputs
gh workflow run "Deploy" --field environment=staging --field version=v1.2.3
gh workflow run "Build" --raw-field config='{"debug": true}'

# Run from specific repo
gh workflow run "CI" --repo owner/repo
```

**Input types:**
- `--field` - String input (e.g., `--field name=value`)
- `--raw-field` - JSON input (e.g., `--raw-field config='{"key": "value"}'`)

## Enabling/Disabling Workflows

```bash
# Enable a workflow
gh workflow enable "CI"

# Disable a workflow
gh workflow disable "CI"

# Enable/disable in specific repo
gh workflow enable "CI" --repo owner/repo
```

## Listing Workflow Runs

```bash
# List recent workflow runs
gh run list

# List for specific workflow
gh run list --workflow "CI"
gh run list --workflow ci.yml

# Filter by status
gh run list --status completed
gh run list --status success
gh run list --status failure
gh run list --status in_progress

# Filter by branch
gh run list --branch main

# Filter by actor (user who triggered)
gh run list --user username

# Filter by event
gh run list --event push
gh run list --event pull_request
gh run list --event workflow_dispatch

# Limit results
gh run list --limit 50

# Get JSON output
gh run list --json databaseId,status,conclusion,headBranch,event,workflowName

# List in specific repo
gh run list --repo owner/repo
```

**Status values:**
- `completed`, `in_progress`, `queued`, `requested`, `waiting`

**Conclusion values (for completed runs):**
- `success`, `failure`, `cancelled`, `skipped`, `timed_out`, `action_required`

**Common events:**
- `push`, `pull_request`, `workflow_dispatch`, `schedule`, `release`

## Viewing Workflow Run Details

```bash
# View run details
gh run view 123456

# View in browser
gh run view 123456 --web

# Show logs
gh run view 123456 --log

# Show failed logs only
gh run view 123456 --log-failed

# Show specific job
gh run view 123456 --job 987654

# Exit with non-zero if run failed
gh run view 123456 --exit-status

# Get JSON output
gh run view 123456 --json status,conclusion,headBranch,workflowName,jobs

# View from specific repo
gh run view 123456 --repo owner/repo
```

## Watching Workflow Runs

```bash
# Watch run progress in real-time
gh run watch 123456

# Watch and show logs
gh run watch 123456 --log

# Watch with exit status
gh run watch 123456 --exit-status

# Watch specific interval (seconds)
gh run watch 123456 --interval 5
```

## Rerunning Workflows

```bash
# Rerun entire workflow
gh run rerun 123456

# Rerun only failed jobs
gh run rerun 123456 --failed

# Rerun specific job
gh run rerun 123456 --job 987654

# Enable debug logging
gh run rerun 123456 --debug

# Rerun from specific repo
gh run rerun 123456 --repo owner/repo
```

## Canceling Workflow Runs

```bash
# Cancel a running workflow
gh run cancel 123456

# Cancel from specific repo
gh run cancel 123456 --repo owner/repo
```

## Downloading Artifacts

```bash
# Download all artifacts from run
gh run download 123456

# Download to specific directory
gh run download 123456 --dir ./artifacts

# Download specific artifact by name
gh run download 123456 --name build-output

# Download from specific repo
gh run download 123456 --repo owner/repo
```

## Deleting Workflow Runs

```bash
# Delete a workflow run (via API)
gh api repos/owner/repo/actions/runs/123456 --method DELETE
```

## Viewing Workflow Logs

```bash
# View logs for a run
gh run view 123456 --log

# View logs for specific job
gh run view 123456 --job 987654 --log

# Download logs
gh api repos/owner/repo/actions/runs/123456/logs > logs.zip
```

## Common Patterns

### Trigger workflow and wait for completion
```bash
# Run workflow
RUN_ID=$(gh workflow run "CI" --json --jq '.id')

# Wait for completion
gh run watch $RUN_ID --exit-status
```

### Get latest run status
```bash
# Get status of latest run for a workflow
gh run list --workflow "CI" --limit 1 --json status,conclusion

# Check if latest run succeeded
CONCLUSION=$(gh run list --workflow "CI" --limit 1 --json conclusion --jq '.[0].conclusion')
if [ "$CONCLUSION" = "success" ]; then
    echo "Latest run succeeded"
fi
```

### Rerun all failed workflows
```bash
# Get all failed runs and rerun them
gh run list --status failure --json databaseId --jq '.[].databaseId' | \
  xargs -I {} gh run rerun {}
```

### Download artifacts from latest run
```bash
# Get latest run ID
RUN_ID=$(gh run list --workflow "CI" --limit 1 --json databaseId --jq '.[0].databaseId')

# Download artifacts
gh run download $RUN_ID
```

### Cancel all running workflows
```bash
# Get all in-progress runs and cancel them
gh run list --status in_progress --json databaseId --jq '.[].databaseId' | \
  xargs -I {} gh run cancel {}
```

### Check workflow status for specific commit
```bash
# List runs for specific commit SHA
gh run list --commit abc123def456
```

### View workflow run duration
```bash
# Get run timing information
gh run view 123456 --json createdAt,updatedAt,runStartedAt
```

### List failed jobs in a run
```bash
# Get failed jobs
gh run view 123456 --json jobs --jq '.jobs[] | select(.conclusion == "failure") | {name: .name, url: .url}'
```

### Trigger workflow with multiple inputs
```bash
gh workflow run "Deploy" \
  --field environment=production \
  --field version=v1.2.3 \
  --field notify=true \
  --raw-field config='{"timeout": 300, "retries": 3}'
```

### Monitor workflow until completion
```bash
# Trigger and monitor
gh workflow run "CI"
sleep 5  # Wait for run to start
RUN_ID=$(gh run list --workflow "CI" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

### Get workflow run URL
```bash
RUN_URL=$(gh run view 123456 --json url --jq '.url')
echo "View run at: $RUN_URL"
```

## Job-Level Operations

While `gh` doesn't have direct job commands, you can work with jobs through runs:

```bash
# View all jobs in a run
gh run view 123456 --json jobs --jq '.jobs[] | {name: .name, status: .status, conclusion: .conclusion}'

# Get specific job logs
gh api repos/owner/repo/actions/jobs/987654/logs
```

## Workflow Dispatch Inputs

For workflows with `workflow_dispatch` trigger, you can pass inputs:

```yaml
# Example workflow with inputs
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        type: choice
        options:
          - staging
          - production
      version:
        description: 'Version to deploy'
        required: true
        type: string
```

```bash
# Trigger with inputs
gh workflow run "deploy.yml" \
  --field environment=staging \
  --field version=v1.2.3
```
