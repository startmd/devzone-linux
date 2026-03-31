# devzone-linux Documentation

Complete reference for all tools, configuration, and architecture.

---

## Table of Contents

1. [Installation](#installation)
2. [setup.sh](#setupsh)
3. [make_vhost](#make_vhost)
4. [fix_web](#fix_web)
5. [lib.sh API](#libsh-api)
6. [Configuration Reference](#configuration-reference)
7. [Architecture](#architecture)
8. [Troubleshooting](#troubleshooting)

---

## Installation

### Prerequisites

- Linux Mint 21+ or Ubuntu 22.04+
- `sudo` access
- Internet connection

### Install

```bash
git clone https://github.com/YOUR_USERNAME/devzone-linux.git
cd devzone-linux
sudo ./install.sh
```

This installs:

| Source | Destination |
|--------|-------------|
| `lib.sh` | `/usr/local/lib/devtools/lib.sh` |
| `setup.sh` | `/usr/local/bin/setup` |
| `make_vhost` | `/usr/local/bin/make_vhost` |
| `fix_web` | `/usr/local/bin/fix_web` |
| `nemo/fix-permissions.nemo_action` | `~/.local/share/nemo/actions/` |

### Uninstall

```bash
sudo rm /usr/local/bin/setup /usr/local/bin/make_vhost /usr/local/bin/fix_web
sudo rm -rf /usr/local/lib/devtools
rm ~/.local/share/nemo/actions/fix-permissions.nemo_action
```

---

## setup.sh

Interactive developer environment installer. Run with `sudo setup`.

### Sections

#### Step 0: Package Manager Preference

Choose your installer backend:

- **apt** — native packages, best integration, recommended
- **flatpak** — sandboxed, auto-updates, flathub.org packages
- **snap** — requires unblock on Linux Mint, Canonical packages

This preference is stored in `$INSTALLER` and used for all subsequent installations.

#### Step 1: Core Essentials

Installs: `curl`, `wget`, `git`, `unzip`, `ca-certificates`, `apt-transport-https`, `gpg`, `software-properties-common`

#### Step 2: IDEs & Editors

Multi-select. Each IDE supports multiple install methods:

| IDE | apt | flatpak | snap |
|-----|-----|---------|------|
| VS Code | Microsoft repo | `com.visualstudio.code` | `code` |
| JetBrains Toolbox | tarball download | — | — |
| Zed | official script | `dev.zed.Zed` | — |
| Pulsar | `pulsar-edit.dev` repo | `dev.pulsar_edit.Pulsar` | `pulsar-edit` |
| Antigravity | Google repo | — | — |
| Cursor | AppImage download | — | — |

JetBrains Toolbox opens a sub-menu for specific IDEs: PhpStorm, WebStorm, PyCharm, IntelliJ IDEA, GoLand, CLion, Rider, RustRover, DataGrip.

#### Step 3: Coding Agents

All installed via `npm install -g`:

| Agent | Package |
|-------|---------|
| Claude Code | `@anthropic-ai/claude-code` |
| Gemini CLI | `@google/gemini-cli` |
| OpenCode | `opencode-ai` |
| KiloCode | `@kilocode/cli` |
| Codex | `@openai/codex` |

#### Step 4: Web Server

Pick one:

- **Apache** — enables `rewrite`, `proxy`, `proxy_http`, `ssl`, `headers`, `expires`
- **Nginx** — configures `worker_processes auto`, `client_max_body_size 48M`, PHP-FPM upstream

#### Step 5: PHP

Multi-select versions: **8.0, 8.1, 8.2, 8.3, 8.4**

Source: [Ondrej PPA](https://launchpad.net/~ondrej/+archive/ubuntu/php)

For each selected version:
1. Installs `phpX.Y` + web server module (`libapache2-mod-phpX.Y` or `phpX.Y-fpm`)
2. Installs extensions: `cli, common, mysql, zip, gd, mbstring, curl, xml, bcmath, intl, soap, xdebug`
3. Patches `php.ini` with production defaults (see [Configuration Reference](#php-ini-defaults))

Prompts for default CLI version.

#### Step 6: Languages

| Language | Install Method | Config |
|----------|---------------|--------|
| Node.js 22.x | Nodesource apt repo | corepack enabled |
| Python | apt (`python3-pip`, `python3-venv`, `python3-dev`) | — |
| Rust | `rustup.rs` official installer | PATH added to `.bashrc` + `.profile` |
| Go | official tarball to `/usr/local/go` | PATH added to `.bashrc` + `.profile` |

#### Step 7: Git

Installs if missing, configures `user.name` and `user.email`.

Optional extras: `gh` (GitHub CLI), `git-lfs`, `tig`.

#### Step 8: Databases

MySQL or MariaDB (mutually exclusive choice, conflicts at package level):
- MySQL or MariaDB: installed + service enabled
- PostgreSQL: installed + service enabled
- SQLite: verified/installed
- Optional dev user creation for both MySQL/MariaDB and PostgreSQL

#### Step 9: Email (Mailpit)

Installs Mailpit binary, creates systemd service, configures PHP `sendmail_path`.

Mailpit UI: `http://localhost:8025`

#### Step 10: Database Admin UI

| Tool | Size | URL |
|------|------|-----|
| AdminerEvo | ~400KB | `http://localhost/adminer` |
| phpMiniAdmin | ~30KB | `http://localhost/phpminiadmin` |
| phpMyAdmin | ~50MB | `http://localhost/phpmyadmin` (with warning) |

#### Step 11: Gitea

Self-hosted Git server. Requires a database (MySQL, MariaDB, or PostgreSQL).

- Downloads latest Gitea binary from official releases
- Creates `git` system user
- Sets up systemd service
- Configures web server reverse proxy at `http://gitea.test`
- Adds `gitea.test` to `/etc/hosts`

Default credentials: database user `gitea` / password `gitea_local_password`

#### Step 12: Web Directory Permissions

Fixes `/var/www/html` ownership and permissions (same as `fix_web`).

---

## make_vhost

Virtual host manager. Auto-detects Apache or Nginx.

### Usage

```
make_vhost [command]
```

| Command | Description |
|---------|-------------|
| `add` (default) | Create a new virtual host |
| `delete` | Remove an existing virtual host |
| `list` | Show all configured virtual hosts |

### Add Flow

1. Prompt for domain (e.g., `myproject.test`)
2. Prompt for project directory (under `/var/www/html/`)
3. Ask if project uses `/public` document root
4. Create directory with ownership
5. Generate default `index.html` if none exists
6. Write server config (Apache VirtualHost or Nginx server block)
7. Add to `/etc/hosts`
8. Enable site and reload server

### Delete Flow

1. Lists all configured vhosts
2. User picks one
3. Removes config, disables site, removes from `/etc/hosts`
4. Optionally deletes project files

### Output Examples

**Apache config:**
```apache
<VirtualHost *:80>
    ServerName myproject.test
    DocumentRoot /var/www/html/myproject/public

    <Directory /var/www/html/myproject/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/myproject.test_error.log
    CustomLog ${APACHE_LOG_DIR}/myproject.test_access.log combined
</VirtualHost>
```

**Nginx config:**
```nginx
server {
    listen 80;
    listen [::]:80;

    server_name myproject.test;
    root /var/www/html/myproject/public;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

---

## fix_web

Web directory permission fixer.

### Usage

```
fix_web [path] [--dry-run]
```

| Argument | Description |
|----------|-------------|
| (none) | Fix `/var/www/html` (default) |
| `path` | Fix specific directory |
| `--dry-run` | Show what would change without applying |
| `--help` | Show usage |

### What It Does

1. Adds current user to `www-data` group
2. `chown -R user:www-data $TARGET`
3. `find $TARGET -type d -exec chmod 2775 {}` (setgid bit — new files inherit www-data group)
4. `find $TARGET -type f -exec chmod 0664 {}` (rw-rw-r--)

### Nemo Integration

Right-click any directory in Nemo file manager → "Fix Web Permissions" (uses `pkexec` for GUI password prompt).

---

## lib.sh API

Shared library sourced by all devzone scripts.

### Global Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `INSTALLER` | `apt` | Package manager backend (apt/flatpak/snap) |
| `WEB_SERVER` | `""` | Detected web server (apache/nginx/none) |
| `ACTUAL_USER` | `""` | Non-root user running sudo |

### Logging Functions

| Function | Output |
|----------|--------|
| `log_info "msg"` | `ℹ  msg` (cyan) |
| `log_ok "msg"` | `✅ msg` (green) |
| `log_warn "msg"` | `⚠  msg` (yellow) |
| `log_err "msg"` | `❌ msg` (red) |
| `log_step "msg"` | `━━━ msg ━━━` (bold blue separator) |
| `log_item "msg"` | `→ msg` (cyan arrow) |
| `separator()` | `=========================================` |

### Interactive Prompts

| Function | Returns |
|----------|---------|
| `ask_permission "prompt"` | `$?=0` for yes, `$?=1` for no |
| `ask_select "prompt" "opt1" "opt2"` | `$SELECTED` (0-based index) |
| `ask_multi "prompt" "opt1" "opt2"` | `$SELECTED_ITEMS` (array of indices) |

### System Functions

| Function | Purpose |
|----------|---------|
| `root_check` | Exit if not root |
| `get_user` | Set `$ACTUAL_USER` from `$SUDO_USER` |
| `detect_web_server` | Set `$WEB_SERVER` (apache/nginx/none) |
| `detect_installer` | Validate `$INSTALLER` is available |
| `is_installed "name"` | Check if command/package exists |

### Install Functions

| Function | Purpose |
|----------|---------|
| `install_app "name" "apt" "flatpak" "snap"` | Route install to correct backend |
| `add_apt_repo "name" "repo" "key_url" "keyring"` | Add GPG key + apt repository |

### Config Functions

| Function | Purpose |
|----------|---------|
| `set_php_ini "file" "key" "value"` | Patch a php.ini value |
| `enable_svc "name"` | systemctl enable --now |
| `ensure_dir "path" "owner" "group"` | Create dir with ownership |
| `run_cmd "desc" command...` | Run command with logging |

---

## Configuration Reference

### PHP ini Defaults

Applied to both `apache2/php.ini` and `fpm/php.ini`:

| Setting | Value | Notes |
|---------|-------|-------|
| `memory_limit` | 512M | Sufficient for most CMS/frameworks |
| `upload_max_filesize` | 48M | Matches typical dev needs |
| `post_max_size` | 48M | Must be ≥ upload_max_filesize |
| `max_execution_time` | 300 | 5 minutes for long imports |
| `max_input_time` | 300 | 5 minutes for large uploads |
| `max_input_vars` | 5000 | Large forms (e.g., WordPress menus) |
| `display_errors` | Off | Use logs instead |
| `date.timezone` | UTC | Change to your timezone if needed |
| `opcache.enable` | 1 | Performance boost |
| `opcache.memory_consumption` | 256 | MB allocated to OPcache |
| `sendmail_path` | `/usr/local/bin/mailpit sendmail` | If Mailpit installed |

CLI `php.ini` overrides:

| Setting | Value |
|---------|-------|
| `memory_limit` | -1 (unlimited) |
| `opcache.enable` | 0 |

### Apache Config Changes

| Directive | Value |
|-----------|-------|
| `Timeout` | 300 |
| `KeepAlive` | On |
| `MaxKeepAliveRequests` | 100 |
| `KeepAliveTimeout` | 5 |
| `ServerTokens` | Prod |
| `ServerSignature` | Off |

Modules enabled: `rewrite`, `proxy`, `proxy_http`, `ssl`, `headers`, `expires`

### Nginx Config Changes

| Directive | Value |
|-----------|-------|
| `worker_processes` | auto |
| `keepalive_timeout` | 65 |
| `client_max_body_size` | 48M |

Default site configured with `index.php` support and PHP-FPM upstream.

### Database Defaults

| DB | Port | Service |
|----|------|---------|
| MySQL | 3306 | `mysql.service` |
| MariaDB | 3306 | `mariadb.service` |
| PostgreSQL | 5432 | `postgresql.service` |
| SQLite | N/A | File-based |

---

## Architecture

### File Structure

```
devzone-linux/
├── install.sh              ← Entry point: copies files to system
├── lib.sh                  ← Shared library (sourced by all scripts)
├── setup.sh                ← Interactive installer (source lib.sh)
├── make_vhost              ← Vhost manager (source lib.sh)
├── fix_web                 ← Permission fixer (source lib.sh)
├── nemo/
│   └── fix-permissions.nemo_action
├── README.md               ← GitHub homepage
└── docs/
    └── DOCUMENTATION.md    ← This file
```

### How It Works

1. `install.sh` copies `lib.sh` to `/usr/local/lib/devtools/`
2. Each CLI tool sources `lib.sh` from the installed location
3. Tools also fallback to local `./lib.sh` if run from source directory
4. `$INSTALLER` variable controls which package backend is used throughout

### Adding New Tools

To add a new tool to `setup.sh`:

1. Add a new section in `setup.sh` with `log_step`
2. Use `ask_permission` or `ask_multi` for user input
3. Use `install_app` for package installation
4. Use `set_php_ini` or config file writes for configuration
5. Add to `lib.sh` if it needs shared helpers

---

## Troubleshooting

### Snap blocked on Linux Mint

Linux Mint blocks snap by default with `/etc/apt/preferences.d/nosnap.pref`. The setup script detects this and offers to remove the blocker. To manually unblock:

```bash
sudo mv /etc/apt/preferences.d/nosnap.pref /etc/apt/preferences.d/nosnap.pref.bak
sudo apt update
sudo apt install snapd
```

### PHP version switching

If multiple PHP versions are installed, set the default CLI version:

```bash
sudo update-alternatives --config php
```

### Apache/Nginx port conflict

Apache and Nginx both listen on port 80. Only one can run at a time:

```bash
sudo systemctl stop apache2
sudo systemctl start nginx
# or vice versa
```

### Permission denied errors

Run `fix_web` to reset permissions:

```bash
sudo fix_web /var/www/html/your-project
```

If you just added yourself to `www-data`, log out and back in for the group change to take effect.

### Node.js agents not found after install

npm global binaries may not be in PATH. Add to `~/.bashrc`:

```bash
export PATH="$PATH:$(npm config get prefix)/bin"
```

### Rust/Go not available in current shell

After installation, source the profile:

```bash
source ~/.cargo/bin/env     # Rust
export PATH=$PATH:/usr/local/go/bin  # Go
```

Or open a new terminal.
