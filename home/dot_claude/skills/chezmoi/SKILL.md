---
name: chezmoi
description: Manage dotfiles with chezmoi — applying changes, editing source templates, previewing diffs, and understanding template variables. Use when the user wants to add, modify, or deploy dotfiles; asks about chezmoi commands or aliases (cz/cze/cza/czd); works with Go templates in this repo; or troubleshoots why a file isn't being applied correctly.
---

# Chezmoi Dotfiles Management

Manage personal dotfiles with [chezmoi](https://github.com/twpayne/chezmoi). The source lives in `~/.dotfiles/home/` (set via `.chezmoiroot`); chezmoi renders templates and writes output to `$HOME`.

## Core Commands

Always work on the **source** files, never the deployed files directly.

```powershell
chezmoi diff            # Preview what would change in $HOME
chezmoi apply           # Apply source → $HOME (also auto-pushes to git)
chezmoi edit ~/.gitconfig   # Open source template for a managed file
chezmoi cat ~/.gitconfig    # Show rendered output without applying
chezmoi doctor          # Check for configuration issues
chezmoi update          # Pull latest from GitHub and apply
chezmoi add <file>      # Start tracking an existing file
chezmoi re-add <file>   # Re-sync source from the deployed file
chezmoi forget <file>   # Stop tracking a file (leaves deployed copy)
chezmoi status          # Show which managed files differ
```

### Aliases (defined in this repo)

| Alias | Expands to |
|-------|-----------|
| `cz`  | `chezmoi` |
| `cze` | `chezmoi edit` |
| `cza` | `chezmoi apply` |
| `czd` | `chezmoi diff` (PowerShell only) |

## Repository Layout

Source root: `~/.dotfiles/home/` (the `home/` directory in the repo).

| Source path | Deployed to | Notes |
|-------------|-------------|-------|
| `dot_gitconfig.tmpl` | `~/.gitconfig` | Templated; Windows gets extra sshCommand and [safe] blocks |
| `dot_bash/bashrc` | `~/.bash/bashrc` | Linux/WSL bash config |
| `symlink_dot_bashrc.tmpl` | `~/.bashrc` | Symlink to the above |
| `dot_local/bin/executable_aliases.sh` | `~/.local/bin/aliases.sh` | Bash aliases + chezmoi wrappers |
| `exact_dot_config/starship.toml.tmpl` | `~/.config/starship.toml` | Starship prompt; templated per OS |
| `private_Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | `$PROFILE` | Windows PowerShell profile |
| `private_AppData/Local/Microsoft/VSCode/settings.json` | VS Code settings | |
| `private_AppData/Local/Microsoft/Windows Terminal/settings.json` | Windows Terminal settings | |
| `private_dot_ssh/private_config.tmpl` | `~/.ssh/config` | SSH config; 1Password SSH agent |
| `dot_claude/` | `~/.claude/` | Claude Code skills and settings |
| `.chezmoiscripts/windows/` | — | PowerShell scripts run on Windows |
| `.chezmoiscripts/linux/` | — | Shell scripts run on Linux/WSL |

## File Name Conventions (Prefixes/Suffixes)

Chezmoi maps file names in the source to their deployed names by stripping these:

| Prefix/suffix | Effect |
|--------------|--------|
| `dot_` | Deployed as a dotfile (e.g. `dot_gitconfig` → `.gitconfig`) |
| `private_` | Deployed with mode `0600` |
| `exact_` | Removes extra files in the target dir not present in source |
| `executable_` | Deployed with execute bit set |
| `symlink_` | Deployed as a symlink |
| `.tmpl` suffix | Processed as a Go template before deployment |
| `run_once_` | Script runs once only |
| `run_onchange_` | Script runs when its content changes |
| Numeric prefix (e.g. `05-`) | Controls script execution order |

## Template Variables

Templates use Go template syntax `{{ .variable }}`. Available variables (from `.chezmoi.yaml.tmpl`):

| Variable | Type | Values |
|----------|------|--------|
| `.chezmoi.os` | string | `"windows"`, `"linux"`, `"darwin"` |
| `.wsl` | bool | `true` when running in WSL2 |
| `.ephemeral` | bool | `true` in cloud/container/CI environments |
| `.headless` | bool | `true` on headless machines |
| `.hostname` | string | Machine hostname |
| `.osid` | string | e.g. `"linux-ubuntu"` |

### Common Template Patterns

```go
{{- if eq .chezmoi.os "windows" }}
# Windows-only config
{{- else if .wsl }}
# WSL2-only config
{{- else }}
# Linux/macOS config
{{- end }}
```

```go
{{- if not .ephemeral }}
# Only on permanent machines
{{- end }}
```

```go
# Use hostname for machine-specific settings
{{- if eq .hostname "my-work-laptop" }}
[work]
  email = work@example.com
{{- end }}
```

## Secrets via 1Password

Secrets come from 1Password via the `op` CLI. The template function `onepasswordRead` fetches them:

```go
{{ onepasswordRead "op://vault/item/field" }}
```

Authenticate before running chezmoi if secrets are needed:
```powershell
# Windows
op signin
# Linux/WSL
eval $(op signin)
```

The 1Password SSH agent must be running for SSH-related operations. `~/.ssh/config` references it.

## Common Workflows

### Add a new dotfile to chezmoi

```powershell
# Track an existing file
chezmoi add ~/.config/myapp/config.toml

# Or create the source file manually in ~/.dotfiles/home/
# then run chezmoi apply
```

### Edit a managed file

```powershell
# Opens the source template in $EDITOR
chezmoi edit ~/.gitconfig

# After editing, preview then apply
chezmoi diff
chezmoi apply
```

### Add a new file to the dotfiles repo

1. Create the file in the correct location under `~/.dotfiles/home/` following naming conventions.
2. Run `chezmoi diff` to confirm the expected change.
3. Run `chezmoi apply` to deploy.
4. `git.autopush: true` means apply also pushes to GitHub automatically.

### Add a platform-specific block to an existing template

Add a `.tmpl` suffix to the source file if it doesn't already have one, then use template conditionals.

### Cross-platform line endings

All files are committed with LF (enforced by `.gitattributes`). `core.autocrlf = input` in `.gitconfig` handles this. Never use CRLF in source files.

## Platform-Specific Notes

- **Windows scripts** use `powershell.exe` (legacy, 64-bit) with `-ExecutionPolicy Bypass` — configured in `.chezmoi.yaml.tmpl` under `interpreters.ps1`
- **`.chezmoiignore`** excludes `*.sh` and `linux/**` scripts on non-Linux, and `AppData`/`Documents` on non-Windows
- **Developer Mode** must be enabled on Windows for chezmoi to create symlinks

## Troubleshooting

### File not being updated
```powershell
chezmoi status          # Check if file is tracked and differs
chezmoi diff ~/.file    # See what would change
chezmoi doctor          # Check for overall issues
```

### Template rendering errors
```powershell
chezmoi cat ~/.file     # Render template and show output without applying
chezmoi execute-template < ~/.dotfiles/home/path/to/file.tmpl  # Test template
```

### File tracked by chezmoi but changes not picked up
```powershell
chezmoi re-add ~/.file  # Sync source from currently deployed file
```

### Conflicts after `chezmoi update`
```powershell
chezmoi diff            # Review all pending changes before applying
chezmoi merge ~/.file   # Three-way merge for a specific file
```

## Reference

- [Chezmoi docs](https://www.chezmoi.io/reference/)
- [Template functions](https://www.chezmoi.io/reference/templates/functions/)
- [`.chezmoi.yaml.tmpl` variables](https://www.chezmoi.io/reference/special-files/chezmoi-format-yaml/)
