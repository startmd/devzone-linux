# devzone-linux

One-command developer environment setup for **Linux Mint** and **Ubuntu**.

Installs and configures IDEs, coding agents, PHP, web servers, databases, and more — all working out of the box.

## What's Included

| Category | Tools |
|----------|-------|
| **IDEs** | VS Code, JetBrains Toolbox, Zed, Antigravity, Cursor |
| **Coding Agents** | Claude Code, Gemini CLI, OpenCode, KiloCode, Codex (installed after Node.js) |
| **Languages** | PHP (8.0–8.4), Node.js, Python, Rust, Go |
| **Web Servers** | Apache or Nginx (your choice) |
| **Databases** | MySQL or MariaDB, PostgreSQL, SQLite |
| **DB Admin** | AdminerEvo, phpMiniAdmin, phpMyAdmin |
| **Git** | Gitea (self-hosted) |
| **Email** | Mailpit (local email testing) |
| **VCS** | Git + GitHub CLI, git-lfs, tig |
| **Tools** | `make_vhost` (add/delete/list vhosts), `fix_web` (permissions), `devzone-setup` (CLI installer) |

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/devzone-linux.git
cd devzone-linux
sudo ./install.sh
sudo devzone-setup
```

## Setup Steps

`sudo devzone-setup` walks you through **13** interactive sections. Each one asks permission before acting — skip what you don't need.

| Step | What It Does |
|------|-------------|
| 0 | Choose package manager: apt, flatpak, or snap |
| 1 | Core essentials (curl, wget, git, gpg, etc.) |
| 2 | IDEs & Editors (multi-select) |
| 3 | Web Server: Apache or Nginx (pick one) |
| 4 | PHP versions 8.0–8.4 (multi-select, auto-configured) |
| 5 | Languages: Node.js, Python, Rust, Go (multi-select) |
| 6 | Coding Agents (multi-select, via npm - installed after Node.js) |
| 7 | Git config + extras (gh, git-lfs, tig) |
| 8 | Databases: MySQL/MariaDB + PostgreSQL + SQLite |
| 9 | Mailpit (local email testing) |
| 10 | DB admin UI: AdminerEvo, phpMiniAdmin, phpMyAdmin |
| 11 | Gitea (self-hosted Git server) |
| 12 | Fix web directory permissions |

## Tools

### `sudo devzone-setup`

Interactive installer with yes/no prompts for each section. Pick what you want — skip what you don't.

Also supports fully non-interactive mode via CLI flags — pass any flag to skip all prompts and install only what you specify:

```bash
sudo devzone-setup                                        # Interactive mode
sudo devzone-setup --web apache --php 8.4                 # Apache + PHP 8.4 only
sudo devzone-setup --web nginx --php 8.2 --php 8.4 --db mariadb
sudo devzone-setup --ide vscode --agent claude --lang nodejs
sudo devzone-setup --gitea --db mariadb --postgresql --web nginx
```

| Flag | Description |
|------|-------------|
| `--installer TYPE` | Package manager: `apt`, `flatpak`, `snap` (default: `apt`) |
| `--essentials` | Install core packages (curl, wget, git, etc.) |
| `--ide NAME` | IDE to install (repeatable): `vscode`, `jetbrains`, `zed`, `antigravity`, `cursor` |
| `--agent NAME` | Coding agent (repeatable): `claude`, `gemini`, `opencode`, `kilo`, `codex` |
| `--web apache\|nginx` | Web server to install |
| `--php VER` | PHP version (repeatable): `8.0`, `8.1`, `8.2`, `8.3`, `8.4` |
| `--php-default VER` | Set default CLI PHP version |
| `--lang NAME` | Language (repeatable): `nodejs`, `python`, `rust`, `go` |
| `--git` | Configure git |
| `--git-name NAME` | Git user.name |
| `--git-email EMAIL` | Git user.email |
| `--git-extras` | Install GitHub CLI, git-lfs, tig |
| `--db mysql\|mariadb` | MySQL or MariaDB |
| `--postgresql` | Install PostgreSQL |
| `--sqlite` | Install SQLite |
| `--db-user USER` | Database dev username |
| `--db-pass PASS` | Database dev password |
| `--mailpit` | Install Mailpit (local email testing) |
| `--db-admin NAME` | DB admin tool (repeatable): `adminer`, `phpminiadmin`, `phpmyadmin` |
| `--gitea` | Install Gitea (self-hosted Git server) |
| `--fix-permissions` | Fix /var/www/html permissions |
| `--help, -h` | Show help |

### `sudo make_vhost`

```
make_vhost            # Add a virtual host (interactive)
make_vhost add        # Same as above
make_vhost delete     # Remove a virtual host
make_vhost list       # Show all configured vhosts
```

Auto-detects Apache or Nginx and generates the correct config format.

### `sudo fix_web`

```
fix_web                          # Fix /var/www/html (default)
fix_web /var/www/html/myproject  # Fix specific directory
fix_web --dry-run                # Preview changes without applying
```

Sets ownership to `user:www-data`, directories to `2775` (setgid), files to `0664`.

## Package Manager

During setup, choose your preferred installer:

- **apt** (recommended) — native packages, best system integration
- **flatpak** — sandboxed, auto-updates, works across distros
- **snap** — requires unblock on Linux Mint

The same tool gets installed via your chosen backend.

## PHP Configuration

When PHP is installed, these values are auto-configured:

| Setting | Web Server | CLI |
|---------|-----------|-----|
| `memory_limit` | 512M | unlimited |
| `upload_max_filesize` | 48M | 2M |
| `post_max_size` | 48M | 8M |
| `max_execution_time` | 300 | 30 |
| `max_input_vars` | 5000 | 5000 |
| `opcache` | enabled | disabled |

## Requirements

- Linux Mint 21+ or Ubuntu 22.04+
- Root access (`sudo`)
- Internet connection

## License

MIT
