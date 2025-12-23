# Gist Operations

Commands for working with GitHub Gists using `gh gist`.

## Quick Reference

- Create: `gh gist create <files>`
- List: `gh gist list`
- View: `gh gist view <gist-id>`
- Edit: `gh gist edit <gist-id>`
- Delete: `gh gist delete <gist-id>`
- Clone: `gh gist clone <gist-id>`

## Creating Gists

```bash
# Create from file
gh gist create myfile.txt

# Create from multiple files
gh gist create file1.txt file2.js file3.md

# Create from stdin
echo "Hello, World!" | gh gist create -

# Create with description
gh gist create myfile.txt --desc "My awesome script"
gh gist create myfile.txt -d "Description here"

# Create as public gist
gh gist create myfile.txt --public
gh gist create myfile.txt -p

# Create as secret gist (default)
gh gist create myfile.txt

# Create with custom filename
gh gist create - --filename "custom-name.txt" < input.txt

# Create from clipboard (if pbpaste/xclip available)
pbpaste | gh gist create - --filename "clipboard.txt"

# Open in browser after creation
gh gist create myfile.txt --web
gh gist create myfile.txt -w
```

**Common flags:**
- `--desc` or `-d` - Gist description
- `--public` or `-p` - Create public gist (default is secret)
- `--filename` or `-f` - Filename for stdin input
- `--web` or `-w` - Open in browser after creation

**Note:** "Secret" gists are unlisted but accessible to anyone with the URL. They are not private.

## Listing Gists

```bash
# List your gists
gh gist list

# Limit results
gh gist list --limit 50

# Include public and secret gists
gh gist list --public
gh gist list --secret

# Get specific fields
gh gist list --json description,files,url,id
```

**Common --json fields:**
- `id`, `description`, `url`, `files`
- `public`, `createdAt`, `updatedAt`

## Viewing Gists

```bash
# View gist content
gh gist view abc123def456

# View in browser
gh gist view abc123def456 --web
gh gist view abc123def456 -w

# View specific file from gist
gh gist view abc123def456 --filename script.sh
gh gist view abc123def456 -f script.sh

# View raw content
gh gist view abc123def456 --raw
gh gist view abc123def456 -r

# Get JSON output
gh gist view abc123def456 --json id,description,files,public
```

## Editing Gists

```bash
# Edit gist interactively (opens editor)
gh gist edit abc123def456

# Edit specific file
gh gist edit abc123def456 --filename script.sh
gh gist edit abc123def456 -f script.sh

# Add file to gist
gh gist edit abc123def456 --add newfile.txt
gh gist edit abc123def456 -a newfile.txt

# Remove file from gist
gh gist edit abc123def456 --remove oldfile.txt

# Update description
gh gist edit abc123def456 --desc "Updated description"
gh gist edit abc123def456 -d "New description"
```

## Deleting Gists

```bash
# Delete a gist
gh gist delete abc123def456

# Delete without confirmation
gh gist delete abc123def456 --confirm
```

## Cloning Gists

```bash
# Clone gist to local directory
gh gist clone abc123def456

# Clone to specific directory
gh gist clone abc123def456 my-gist-dir
```

## Renaming Gist Files

```bash
# Rename file in gist (requires API call)
gh api gists/abc123def456 --method PATCH \
  --field "files[oldname.txt][filename]=newname.txt"
```

## Common Patterns

### Quick code sharing
```bash
# Share code snippet quickly
cat script.sh | gh gist create --public --desc "Useful script"
```

### Create gist from command output
```bash
# Save command output as gist
ls -la | gh gist create --filename "directory-listing.txt" --desc "Directory contents"
```

### Backup config file as gist
```bash
gh gist create ~/.vimrc --desc "My vim configuration"
```

### Get gist URL
```bash
GIST_URL=$(gh gist create myfile.txt --json url --jq '.url')
echo "Gist available at: $GIST_URL"
```

### Get gist raw URL
```bash
# View and extract raw file URL
gh gist view abc123def456 --json files --jq '.files["script.sh"].raw_url'
```

### Download gist file directly
```bash
# Get raw URL and download
RAW_URL=$(gh gist view abc123def456 --json files --jq -r '.files["script.sh"].raw_url')
curl -o script.sh "$RAW_URL"
```

### Create multi-file gist
```bash
# Share multiple related files
gh gist create \
  index.html \
  style.css \
  script.js \
  --desc "Simple web page example" \
  --public
```

### List recent gists
```bash
gh gist list --limit 10
```

### Find gist by description
```bash
gh gist list --json id,description | \
  jq '.[] | select(.description | contains("keyword"))'
```

### Create from directory (workaround)
```bash
# Gist all files in current directory
find . -type f -maxdepth 1 -exec gh gist create {} + --desc "Directory backup"
```

### Update gist file
```bash
# Edit and replace content
echo "Updated content" > temp.txt
gh gist edit abc123def456 --add temp.txt
rm temp.txt
```

### Check if gist is public
```bash
IS_PUBLIC=$(gh gist view abc123def456 --json public --jq '.public')
if [ "$IS_PUBLIC" = "true" ]; then
    echo "Gist is public"
else
    echo "Gist is secret"
fi
```

### Fork a gist
```bash
# Via API
gh api gists/abc123def456/forks --method POST
```

### Star a gist
```bash
# Star gist
gh api gists/abc123def456/star --method PUT

# Unstar gist
gh api gists/abc123def456/star --method DELETE

# Check if starred
gh api gists/abc123def456/star
```

### List starred gists
```bash
gh api gists/starred
```

### Get gist revision history
```bash
# View commits/revisions
gh api gists/abc123def456/commits
```

## Gist Limitations

- Maximum 100 files per gist
- Maximum 1 MB per file
- Secret gists are unlisted, not private
- No folders/directory structure

## Working with Gist Git Repositories

Gists are full git repositories:

```bash
# Clone gist
gh gist clone abc123def456

# Make changes
cd abc123def456
echo "new content" >> file.txt
git add .
git commit -m "Update file"
git push

# Pull latest changes
git pull
```

## Creating Gists Programmatically

For more complex gist creation:

```bash
# Create multi-file gist via API
gh api gists --method POST \
  --field "description=My gist" \
  --field "public=true" \
  --raw-field 'files={
    "file1.txt": {"content": "Hello"},
    "file2.js": {"content": "console.log(\"Hi\");"}
  }'
```

## Gist Embedding

After creating a public gist, you can embed it in web pages:

```html
<script src="https://gist.github.com/username/abc123def456.js"></script>
```

Get embed URL:
```bash
GIST_ID=$(gh gist create script.js --public --json id --jq '.id')
echo "<script src=\"https://gist.github.com/$(gh api user --jq '.login')/${GIST_ID}.js\"></script>"
```
