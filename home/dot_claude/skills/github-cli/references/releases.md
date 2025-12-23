# Release Management

Commands for working with GitHub releases using `gh release`.

## Quick Reference

- Create: `gh release create <tag>`
- List: `gh release list`
- View: `gh release view <tag>`
- Download: `gh release download <tag>`
- Upload: `gh release upload <tag> <files>`
- Delete: `gh release delete <tag>`
- Edit: `gh release edit <tag>`

## Creating Releases

```bash
# Create release from existing tag
gh release create v1.0.0

# Create release and tag together
gh release create v1.0.0 --title "Version 1.0.0" --notes "Release notes here"

# Create from notes file
gh release create v1.0.0 --title "v1.0.0" --notes-file CHANGELOG.md

# Auto-generate release notes
gh release create v1.0.0 --generate-notes

# Create as draft
gh release create v1.0.0 --draft --title "Draft Release"

# Create as prerelease
gh release create v1.0.0 --prerelease --title "Beta Release"

# Create with asset files
gh release create v1.0.0 \
  --title "Release 1.0.0" \
  --notes "New features..." \
  dist/app-linux.tar.gz \
  dist/app-macos.zip \
  dist/app-windows.zip

# Create with custom asset labels
gh release create v1.0.0 app.zip#"Application Binary"

# Set as latest
gh release create v1.0.0 --latest

# Don't set as latest (for older versions)
gh release create v0.9.0 --latest=false

# Create from specific commit
gh release create v1.0.0 --target main

# Open in browser after creation
gh release create v1.0.0 --title "Release" --web

# Create in specific repo
gh release create v1.0.0 --repo owner/repo
```

**Common flags:**
- `--title` - Release title
- `--notes` - Release notes text
- `--notes-file` - Read notes from file
- `--generate-notes` - Auto-generate from commits
- `--draft` - Create as draft
- `--prerelease` - Mark as prerelease
- `--latest` - Set as latest release
- `--target` - Commit/branch to tag (default: default branch)
- `--discussion-category` - Create discussion in category

## Listing Releases

```bash
# List releases
gh release list

# Limit results
gh release list --limit 20

# Exclude drafts
gh release list --exclude-drafts

# Exclude prereleases
gh release list --exclude-pre-releases

# Get JSON output
gh release list --json tagName,name,isPrerelease,isDraft,createdAt

# List in specific repo
gh release list --repo owner/repo
```

**Common --json fields:**
- `tagName`, `name`, `body`, `url`
- `isDraft`, `isPrerelease`, `isLatest`
- `createdAt`, `publishedAt`
- `author`, `targetCommitish`
- `assets` (array of uploaded files)

## Viewing Release Details

```bash
# View latest release
gh release view

# View specific release
gh release view v1.0.0

# View in browser
gh release view v1.0.0 --web

# Get JSON output
gh release view v1.0.0 --json tagName,name,body,assets,url

# View from specific repo
gh release view v1.0.0 --repo owner/repo
```

## Downloading Release Assets

```bash
# Download all assets from latest release
gh release download

# Download from specific release
gh release download v1.0.0

# Download to specific directory
gh release download v1.0.0 --dir ./downloads

# Download specific asset by pattern
gh release download v1.0.0 --pattern "*.zip"
gh release download v1.0.0 --pattern "*-linux-*"

# Skip existing files
gh release download v1.0.0 --skip-existing

# Download from specific repo
gh release download v1.0.0 --repo owner/repo

# Clobber existing files
gh release download v1.0.0 --clobber
```

**Pattern matching:**
- Use glob patterns: `*.tar.gz`, `app-*`, `*-linux-amd64`
- Multiple patterns: `--pattern "*.zip" --pattern "*.tar.gz"`

## Uploading Assets

```bash
# Upload files to existing release
gh release upload v1.0.0 dist/app.zip

# Upload multiple files
gh release upload v1.0.0 dist/*.zip dist/*.tar.gz

# Upload with custom label
gh release upload v1.0.0 app.zip#"Application Binary"

# Overwrite existing assets
gh release upload v1.0.0 app.zip --clobber

# Upload to specific repo
gh release upload v1.0.0 app.zip --repo owner/repo
```

## Editing Releases

```bash
# Edit release title
gh release edit v1.0.0 --title "New Title"

# Edit release notes
gh release edit v1.0.0 --notes "Updated release notes"

# Edit from notes file
gh release edit v1.0.0 --notes-file CHANGELOG.md

# Mark as draft
gh release edit v1.0.0 --draft

# Publish draft (remove draft status)
gh release edit v1.0.0 --draft=false

# Mark as prerelease
gh release edit v1.0.0 --prerelease

# Remove prerelease status
gh release edit v1.0.0 --prerelease=false

# Set as latest
gh release edit v1.0.0 --latest

# Remove latest status
gh release edit v1.0.0 --latest=false

# Create discussion
gh release edit v1.0.0 --discussion-category "Announcements"

# Verify tag signature (for signed tags)
gh release edit v1.0.0 --verify-tag

# Edit in specific repo
gh release edit v1.0.0 --repo owner/repo
```

## Deleting Releases

```bash
# Delete release (keeps tag)
gh release delete v1.0.0

# Delete release and tag
gh release delete v1.0.0 --yes

# Delete without confirmation
gh release delete v1.0.0 --yes

# Delete from specific repo
gh release delete v1.0.0 --repo owner/repo
```

**Note:** By default, deleting a release keeps the associated git tag. The tag must be deleted separately if needed.

## Deleting Release Assets

```bash
# Delete specific asset (via API)
ASSET_ID=$(gh release view v1.0.0 --json assets --jq '.assets[] | select(.name == "old-file.zip") | .id')
gh api repos/owner/repo/releases/assets/$ASSET_ID --method DELETE
```

## Common Patterns

### Create release with changelog
```bash
# Generate changelog and create release
gh release create v1.0.0 \
  --title "Release 1.0.0" \
  --generate-notes \
  dist/*.zip
```

### Publish draft release
```bash
# Create as draft first
gh release create v1.0.0 --draft --title "v1.0.0"

# Upload assets
gh release upload v1.0.0 dist/*.zip

# Publish when ready
gh release edit v1.0.0 --draft=false
```

### Get latest release tag
```bash
LATEST=$(gh release list --limit 1 --json tagName --jq '.[0].tagName')
echo "Latest release: $LATEST"
```

### Download specific file from latest release
```bash
gh release download --pattern "app-linux-amd64"
```

### Create release from CI/CD
```bash
# In GitHub Actions or CI environment
VERSION=$(git describe --tags --abbrev=0)
gh release create $VERSION \
  --title "Release $VERSION" \
  --generate-notes \
  --verify-tag \
  dist/*
```

### List all release assets
```bash
gh release view v1.0.0 --json assets --jq '.assets[] | {name: .name, size: .size, downloadCount: .downloadCount}'
```

### Get release download count
```bash
# Total downloads for a release
gh release view v1.0.0 --json assets --jq '[.assets[].downloadCount] | add'
```

### Check if release exists
```bash
if gh release view v1.0.0 &>/dev/null; then
    echo "Release exists"
else
    echo "Release not found"
fi
```

### Upload build artifacts after creation
```bash
# Create release
gh release create v1.0.0 --draft

# Build artifacts
make build

# Upload artifacts
gh release upload v1.0.0 dist/*

# Publish
gh release edit v1.0.0 --draft=false
```

### Create beta/prerelease
```bash
gh release create v2.0.0-beta.1 \
  --prerelease \
  --title "v2.0.0 Beta 1" \
  --notes "This is a beta release. Use with caution." \
  dist/*.zip
```

### Update release notes only
```bash
gh release edit v1.0.0 --notes "$(cat RELEASE_NOTES.md)"
```

### Promote prerelease to stable
```bash
gh release edit v1.0.0 --prerelease=false --latest
```

## Release Notes Auto-Generation

When using `--generate-notes`, GitHub will:
1. Generate notes from merged PRs since the last release
2. Group changes by PR labels (features, bugs, etc.)
3. Include contributor list
4. Use `.github/release.yml` config if present

Example `.github/release.yml`:
```yaml
changelog:
  categories:
    - title: Breaking Changes
      labels:
        - breaking-change
    - title: New Features
      labels:
        - enhancement
    - title: Bug Fixes
      labels:
        - bug
  exclude:
    labels:
      - skip-changelog
```

## Tag Management

Releases are associated with git tags. Related tag operations:

```bash
# List tags
git tag -l

# Create annotated tag locally
git tag -a v1.0.0 -m "Version 1.0.0"

# Push tag to remote
git push origin v1.0.0

# Delete tag locally
git tag -d v1.0.0

# Delete tag remotely
git push origin --delete v1.0.0

# View tag details
git show v1.0.0
```
