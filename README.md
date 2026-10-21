# 🧩 github.com/qnimbus/dotfiles

Bas' dotfiles, managed with [`chezmoi`](https://github.com/twpayne/chezmoi).

Install them with:

```console
$ sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init -S "$HOME/.dotfiles" --apply qnimbus
```

Personal secrets are stored in [1Password](https://1password.com) and you'll
need the [1Password CLI](https://developer.1password.com/docs/cli/) installed.
Login to 1Password with:

```console
$ eval $(op signin)
```

---

## 🚀 Quick start on a new system

### 1. Install chezmoi

**Windows**
```powershell
winget install twpayne.chezmoi --source winget
````

> **⚠️ Windows users:** Enable **Developer Mode** to allow chezmoi to create symlinks.
> 
> Go to **Settings** → **Privacy & Security** → **For developers** → toggle **Developer Mode** on.
> 
> Alternatively, run this PowerShell command as Administrator:
> ```powershell
> reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
> ```

**macOS**

```bash
brew install chezmoi
```

**Debian/Ubuntu**

```bash
sudo apt update && sudo apt install -y chezmoi
```

---

### 2. Initialize from this repo

```bash
chezmoi -S "$HOME/.dotfiles" init --apply qnimbus
```

This clones the repo into `~/.dotfiles`, renders all templates,
and writes the resulting files into your home directory.

---

### 3. Verify and apply

```bash
chezmoi doctor          # check environment
chezmoi diff            # preview changes
chezmoi apply           # apply changes
```

Then open a **new shell session** to load everything.

---

## ⚙️ Updating later

```bash
chezmoi update          # pull latest changes from GitHub
chezmoi diff            # see what will change
chezmoi apply           # apply updates
```

---

## 🧠 Notes

* Git configuration (`~/.gitconfig`) is **templated**:

  * Uses `autocrlf = input` and `eol = lf` for consistent line endings on all OSes.
  * Adds a Windows-only `sshCommand` override to force `C:/Windows/System32/OpenSSH/ssh.exe`.

* PowerShell profile (`$PROFILE`) is managed via chezmoi and can include platform-specific logic.

* Default editor for chezmoi is **VS Code** (`code --wait --reuse-window`).

---

## 🪄 Tips

* Edit a managed file (templates included):

  ```bash
  chezmoi edit ~/.gitconfig
  ```
* Show the rendered version:

  ```bash
  chezmoi cat ~/.gitconfig
  ```
* Explore the source repo:

  ```bash
  chezmoi cd
  ```
* On Unix/macOS, you can bootstrap with a single line:

  ```bash
  sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init -S "$HOME/.dotfiles" --apply qnimbus
  ```

---

## 🔐 1Password SSH Agent

This setup assumes the [1Password SSH Agent](https://developer.1password.com/docs/ssh/)
is enabled (Developer → *Use SSH agent*).
Your `~/.ssh/config` includes the `1Password/config` automatically;
chezmoi’s `.gitconfig` templates a Windows-specific `sshCommand` to use it.

---

## 🐳 Docker in WSL (no Docker Desktop)

On WSL Ubuntu, two scripts run on **every** `chezmoi apply` / `chezmoi update`.
Each checks first without sudo and only asks for your password when something is missing or has drifted:

| Script | What it ensures |
|--------|-----------------|
| `run_before_11-configure-wsl-conf.sh` | Merges the keys in `.chezmoitemplates/wsl.conf` (`[boot] systemd=true`) into `/etc/wsl.conf`, keeping all other settings |
| `run_before_12-install-docker.sh` | Docker's official apt repo, `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`; `docker` and `containerd` enabled in systemd; you in the `docker` group |

Package upgrades come from the normal `sudo apt upgrade`, not from chezmoi.

**Manual step:** after the first run (or any `wsl.conf` change), restart WSL so systemd starts and the new group membership applies:

```powershell
wsl --shutdown   # from Windows; then reopen the Ubuntu terminal
```

Check it with:

```bash
systemctl is-system-running        # "running" (or "degraded")
systemctl status docker --no-pager
docker run --rm hello-world
docker compose version
```

**Security:** members of the `docker` group can control the Docker daemon, which runs as root.
That is the same as passwordless root (for example `docker run -v /:/host ...`).
Only add trusted users. For stricter isolation, use [rootless Docker](https://docs.docker.com/engine/security/rootless/).

---

## 🧹 Line-ending policy

Dotfiles are committed with **LF endings** for portability.

```bash
git config --global core.autocrlf input
git config --global core.eol lf
```

A `.gitattributes` file in the repo enforces this:

```
* text eol=lf
```

---

**Author:** [Bas van Wetten](https://github.com/qnimbus)
**License:** MIT
