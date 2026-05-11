# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed with [chezmoi](https://github.com/twpayne/chezmoi). The source directory is `~/.dotfiles/home/` (set via `.chezmoiroot`). Chezmoi renders templates and writes output into `$HOME`.

## Key chezmoi commands

```bash
chezmoi diff            # preview what would change in $HOME
chezmoi apply           # apply source → $HOME
chezmoi edit ~/.gitconfig   # edit the source template for a managed file
chezmoi cat ~/.gitconfig    # show the rendered output without applying
chezmoi doctor          # check for configuration issues
chezmoi update          # pull latest from GitHub and apply
```

Shortcut aliases defined in `~/.local/bin/aliases.sh` (bash) and the PowerShell profile:

| Alias | Expands to |
|-------|-----------|
| `cz`  | `chezmoi` |
| `cze` | `chezmoi edit` |
| `cza` | `chezmoi apply` |
| `czd` | `chezmoi diff` (PowerShell only) |

## Repository layout (under `home/`)

| Path | Deployed to | Notes |
|------|-------------|-------|
| `dot_gitconfig.tmpl` | `~/.gitconfig` | Templated; Windows gets extra `sshCommand` and `[safe]` blocks |
| `dot_bash/bashrc` | `~/.bash` (sourced as `~/.bashrc`) | Linux/WSL bash config |
| `symlink_dot_bashrc.tmpl` | `~/.bashrc` | Symlink to the above |
| `dot_local/bin/executable_aliases.sh` | `~/.local/bin/aliases.sh` | Bash aliases + chezmoi wrappers |
| `exact_dot_config/starship.toml.tmpl` | `~/.config/starship.toml` | Starship prompt; templated per OS |
| `private_Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | `$PROFILE` | Windows PowerShell profile |
| `private_AppData/Local/Microsoft/VSCode/settings.json` | VS Code settings | |
| `private_AppData/Local/Microsoft/Windows Terminal/settings.json` | Windows Terminal settings | |
| `private_dot_ssh/private_config.tmpl` | `~/.ssh/config` | SSH config; uses 1Password SSH agent |
| `.chezmoiscripts/windows/` | — | PowerShell scripts run by chezmoi on Windows |
| `.chezmoiscripts/linux/` | — | Shell scripts run by chezmoi on Linux/WSL |
| `dot_claude/` | `~/.claude/` | Claude Code skills and settings |

## Chezmoi conventions used here

- **`dot_` prefix** → deploys as a dotfile (e.g. `dot_gitconfig` → `.gitconfig`)
- **`private_` prefix** → deployed with mode `0600`
- **`exact_` prefix** → chezmoi removes files in the target dir that aren't in source
- **`executable_` prefix** → deployed with execute bit set
- **`.tmpl` suffix** → Go template processed before deployment
- **`symlink_` prefix** → deployed as a symlink
- **`run_once_` / `run_onchange_` prefixes** → scripts run once or when content changes
- **Script ordering** → numeric prefix (e.g. `05-`, `10-`) controls execution order

## Template data

Templates have access to these variables (defined in `.chezmoi.yaml.tmpl`):

| Variable | Type | Description |
|----------|------|-------------|
| `.chezmoi.os` | string | `"windows"`, `"linux"`, `"darwin"` |
| `.wsl` | bool | `true` when running in WSL2 |
| `.ephemeral` | bool | `true` in cloud/container/CI environments |
| `.headless` | bool | `true` on headless machines |
| `.hostname` | string | Machine hostname |
| `.osid` | string | e.g. `"linux-ubuntu"` |

## Secrets

Secrets come from 1Password via the [1Password CLI](https://developer.1password.com/docs/cli/) (`op`). Authenticate with:

```bash
eval $(op signin)
```

The 1Password SSH agent is assumed to be running; `~/.ssh/config` references it, and `.gitconfig` templates the SSH signing program path per OS.

## Platform-specific notes

- **Windows scripts** use `powershell.exe` (legacy, 64-bit) with `-ExecutionPolicy Bypass` — configured in `.chezmoi.yaml.tmpl` under `interpreters.ps1`
- **`.chezmoiignore`** excludes `*.sh` and `linux/**` scripts on non-Linux, and `AppData`/`Documents` on non-Windows
- **Line endings**: all files committed with LF (enforced by `.gitattributes`); `core.autocrlf = input` in `.gitconfig`
- **`git.autopush: true`** in chezmoi config means `chezmoi apply` auto-pushes changes to git
- **Developer Mode** must be enabled on Windows for chezmoi to create symlinks
