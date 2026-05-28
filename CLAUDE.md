# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for the user, managed with [chezmoi](https://github.com/twpayne/chezmoi) v2.66.0. The source lives in `~/.dotfiles`; chezmoi renders templates and deploys files into the home directory. Supports Windows (primary), Linux, and macOS. Secrets are stored in 1Password and accessed via the `op` CLI.

## Chezmoi Naming Conventions

Files and directories under `home/` use chezmoi's prefix/suffix encoding. Prefixes stack left-to-right in the order shown. Full reference: <https://www.chezmoi.io/reference/source-state-attributes/>

**File/directory prefixes**

| Prefix | Meaning |
|--------|---------|
| `dot_` | Adds a leading `.` to the target name (e.g., `dot_gitconfig` → `~/.gitconfig`) |
| `private_` | Strips group and world read permissions |
| `readonly_` | Removes write permissions |
| `exact_` | Removes unmanaged entries from the target directory |
| `encrypted_` | Encrypts contents in the source state |
| `empty_` | Preserves empty files (chezmoi skips empty files by default) |
| `executable_` | Grants execute permission |
| `create_` | Creates the file only if it does not already exist |
| `symlink_` | Creates a symlink rather than copying the file |
| `literal_` | Stops attribute parsing (use to escape conflicts) |
| `remove_` | Deletes the target file/symlink/empty directory |
| `modify_` | Script that modifies an existing file in-place |
| `run_` | Executes as a script |
| `run_once_` | Runs once, keyed on content hash |
| `run_onchange_` | Re-runs whenever content changes |
| `before_` | Runs before files are updated |
| `after_` | Runs after files are updated |

**Suffixes**

| Suffix | Meaning |
|--------|---------|
| `.tmpl` | Evaluates contents as a Go template at apply time |
| `.age` | Age-encrypted file (suffix stripped in target) |
| `.asc` | GPG-encrypted file (suffix stripped in target) |

**Template data variables** — run `chezmoi data` to see all available values. Built-ins: `.chezmoi.os`, `.chezmoi.hostname`, `.chezmoi.homeDir`, `.chezmoi.osRelease`. Custom (defined in `.chezmoi.yaml.tmpl`): `data.ephemeral`, `data.headless`, `data.wsl`, `data.osid`.

## Common Commands

Full command reference: <https://www.chezmoi.io/reference/commands/>

```bash
# Inspect
chezmoi doctor                    # check environment health
chezmoi data                      # dump all template variables as JSON
chezmoi diff                      # preview changes before applying
chezmoi status                    # short status of pending changes

# Apply
chezmoi apply                     # apply source to home directory
chezmoi update                    # pull latest from GitHub then apply

# Edit
chezmoi edit ~/.gitconfig         # edit managed file (opens in VS Code)
chezmoi edit --apply ~/.gitconfig # edit and immediately apply

# Introspect
chezmoi cat ~/.gitconfig          # show rendered output without applying
chezmoi execute-template          # test/validate template expressions
chezmoi cd                        # open subshell in source directory (~/.dotfiles)

# Add new files
chezmoi add ~/.newfile            # bring an existing file under management
chezmoi add --template ~/.newfile # bring in as a template
chezmoi chattr +template ~/.file  # convert existing managed file to template
```

## Architecture

```
home/
├── .chezmoi.yaml.tmpl        # chezmoi config: source dir, git autopush, PS1 interpreter, template data
├── .chezmoiignore            # platform-conditional exclusions (Linux scripts on Windows, AppData on non-Windows)
├── .chezmoiscripts/
│   ├── windows/              # PowerShell bootstrap scripts (install tools, configure VS Code)
│   └── linux/                # Bash bootstrap scripts (starship, VS Code)
├── dot_gitconfig.tmpl        # Git config: SSH signing via 1Password, LF line endings
├── dot_bash/                 # bashrc, sources starship and aliases
├── dot_local/bin/aliases.sh  # shell aliases sourced by bashrc
├── exact_dot_config/
│   └── starship.toml.tmpl    # Starship prompt (gruvbox-rainbow, cross-platform)
├── private_dot_ssh/
│   └── config.tmpl           # SSH config with 1Password agent include (Windows-specific)
├── private_AppData/          # Windows: VS Code settings, Windows Terminal settings
├── private_Documents/PowerShell/
│   └── Microsoft.PowerShell_profile.ps1  # PS7 profile: aliases, chezmoi helpers, daily update checks
└── dot_claude/skills/        # Claude Code skills: 1password, github-cli, ssh
```

**Bootstrap order** (Windows): chezmoi runs `run_onchange_before_*` scripts first (install pwsh, starship, nerd-fonts, 1password, op CLI, vscode, git), deploys files, then `run_onchange_after_*` (configure vscode, remove bloat).

## Platform Handling

- Scripts: `.sh` files are ignored on non-Linux; `.ps1` files under `windows/` are ignored on non-Windows
- Templates use `{{ if eq .chezmoi.os "windows" }}` guards for platform-specific config blocks
- WSL is detected via `/proc/version` and `/proc/sys/fs/binfmt_misc/WSLInterop`; `data.wsl = true` is set accordingly
- Ephemeral machines (Codespaces, Docker, Vagrant) set `data.ephemeral = true` to skip interactive prompts

## Line Endings

All files are committed with **LF endings**. `.gitattributes` enforces `* text eol=lf`. Git config sets `autocrlf = input` and `eol = lf`. Do not commit CRLF files.

## 1Password Integration

Full docs: <https://www.chezmoi.io/user-guide/password-managers/1password/>

- Git commit signing uses an ed25519 SSH key via 1Password SSH agent
- `~/.ssh/config` includes the 1Password config file (Windows path)
- The `dot_claude/skills/1password/` skill provides helpers for retrieving secrets without displaying them in output
- Never hard-code credentials; use `op read` or the 1password skill instead

**Template functions available in `.tmpl` files:**

```
{{ onepasswordRead "op://vault/item/field" }}          # raw string read
{{ onepassword "uuid" }}                               # full item as parsed JSON
{{ (onepasswordDetailsFields "uuid").password.value }} # field lookup by label
{{ onepasswordDocument "uuid" }}                       # retrieve a document
```

`chezmoi.yaml.tmpl` configures `onepassword.mode` (default: `account` — interactive CLI prompts). Alternatives: `connect` (Connect server) and `service` (service account token).

## Windows Symlinks

Chezmoi creates symlinks on Windows, which requires **Developer Mode** enabled (Settings → Privacy & Security → For developers). Without it, chezmoi falls back to copying files.

## References

| Topic | URL |
|-------|-----|
| chezmoi home | <https://www.chezmoi.io/> |
| Quick start | <https://www.chezmoi.io/quick-start/> |
| User guide | <https://www.chezmoi.io/user-guide/setup/> |
| Templating guide | <https://www.chezmoi.io/user-guide/templating/> |
| Source state attributes (naming conventions) | <https://www.chezmoi.io/reference/source-state-attributes/> |
| Special files (`.chezmoiignore`, `.chezmoiroot`, etc.) | <https://www.chezmoi.io/reference/special-files/> |
| Commands reference | <https://www.chezmoi.io/reference/commands/> |
| 1Password integration | <https://www.chezmoi.io/user-guide/password-managers/1password/> |
| GitHub repository | <https://github.com/twpayne/chezmoi> |
