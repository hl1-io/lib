# Base System

> **AI Disclosure:** This documentation was written by an AI assistant and may contain errors or inaccuracies. Please verify any configuration options against the source code before use. Items marked `<!-- TODO -->` require human review.

The base system modules (`base-system/`) provide shared OS configuration applied to all nodes. They are exposed as `personas.base`, `personas.linux`, and `personas.darwin`.

---

## `personas.base` — Common Configuration

**Source:** `base-system/default.nix`

The base persona is the foundation for every node. It installs a curated package set, configures the shell environment, and sets up [home-manager](https://github.com/nix-community/home-manager) for both `root` and the primary user.

### Package Set

The following packages are installed system-wide:

**Editors & Language Servers**
- `helix` — modal text editor
- `nixd` — Nix language server
- `nil` — alternative Nix language server

**Shell & Navigation**
- `fish` — friendly interactive shell (set as default)
- `xplr` — terminal file explorer
- `fd` — fast `find` replacement
- `ripgrep` — fast grep

**File Viewing**
- `lsd` — `ls` with icons and colour
- `bat` — `cat` with syntax highlighting
- `duf` — disk usage overview
- `dust` — directory size breakdown
- `visidata` — terminal spreadsheet viewer

**System Monitoring**
- `btop` — resource monitor

**CLI Utilities**
- `wget`, `git`, `jq`, `yq` — standard tools
- `magic-wormhole` — secure file transfer
- `step-cli` — certificate management (ACME / OIDC)
- `openssl`, `pciutils` — system diagnostics
- `asciinema` — terminal recording

**Documentation & Markdown**
- `pandoc` — document converter
- `glow` — markdown pager
- `frogmouth` — markdown browser
- `marksman` — Markdown language server
- `viu` — terminal image viewer
- `tv` — terminal file viewer <!-- TODO: Verify exact package name and purpose -->

### Shell Aliases

The following aliases are configured globally:

| Alias | Replaces | Tool |
|-------|---------|------|
| `ls` | `ls` | `lsd` |
| `cat` | `cat` | `bat` |
| `watch` | `watch` | `viddy` |
| `find` | `find` | `fd` |

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `VAULT_ADDR` | `http://vault.services.c.${domains.primary}:${vault.port}` | Points all Vault CLI tools to the cluster Vault server |

### CA Certificates

The base system installs custom CA certificates from `base-system/certs/`:
- Root CA certificate
- Host CA certificate

These are added to the system trust store so that services using internal PKI work correctly.

### Home-Manager

Home-manager is configured for:
- `root`
- The user defined in `hl1-io.profile.username`

**Default user configuration** (`base-system/default-user.nix`) sets up:
- Helix editor with sensible defaults
- Git with name/email from `hl1-io.profile`
- Shell integrations

### NixOS Settings

| Setting | Value |
|---------|-------|
| `system.stateVersion` | `"23.05"` (overridable) |
| `time.timeZone` | `"America/Chicago"` (overridable) <!-- TODO: Confirm if this is the actual default --> |
| `nix.settings.experimental-features` | `[ "nix-command" "flakes" ]` |

---

## `personas.linux` — Linux Configuration

**Source:** `base-system/linux.nix`

Linux-specific system setup applied on top of `personas.base`.

### SSH Server

- OpenSSH enabled with public-key authentication
- SSH CA key installed for host certificate verification
- Host certificates provisioned from `base-system/pubkeys/`

### User Account

A normal user account is created with:
- Username: `hl1-io.profile.username`
- Home directory: `/home/${username}`
- Git and Docker group memberships

### NFS & Storage

- `nfs-utils` installed for NFS client support
- `usbutils` installed

### Disabled Services

The following services are explicitly disabled to reduce attack surface and resource usage:

- Printing (CUPS)
- PulseAudio
- X11 / graphical session

### Nix Store Optimization

Automatic Nix store garbage collection and optimization is enabled.

### Backups

When `hl1-io.backup.nfs` or `hl1-io.backup.paths` are configured, rsnapshot backup jobs are activated. See [Backups](#backups) below.

### Monitoring Client

When `hl1-io.monitoring.client.enable = true` (the default), Promtail is configured to ship logs to the monitoring sink. See [Monitoring Client](#monitoring-client) below.

---

## `personas.darwin` — macOS Configuration

**Source:** `base-system/darwin.nix`

macOS-specific configuration for developer machines using [nix-darwin](https://github.com/LnL7/nix-darwin).

- **Nerd Fonts:** Hack Nerd Font installed
- **User creation:** User account created using `hl1-io.profile.email` as the username <!-- TODO: Verify whether email or username is used on Darwin -->
- Known users configured for reproducible user management

---

## Backups

**Source:** `base-system/backups.nix`

Backup configuration uses [rsnapshot](https://rsnapshot.org/) with a daily timer.

### Default Backup Paths

The following paths are backed up on all Linux nodes:
- `/home`
- `/root`
- Any additional paths in `hl1-io.backup.paths`

### Excluded Paths

The backup excludes common build artifact and cache directories:
- `node_modules/`
- `.cache/`
- `vendor/` directories
- Various OS and tool caches

### Backup Schedule

- **Timer:** Daily, with a randomized delay of up to 4 hours (to avoid thundering herd on shared NFS)
- **Retention:** Configurable via `hl1-io.backup.dailyRetention` (default: 365 days)

### NFS Destination

If `hl1-io.backup.nfs` is set, rsnapshot uses the NFS mount as its backup destination. The NFS share is auto-mounted before backup and unmounted afterwards.

### Backup Scripts

Custom scripts can generate data that is included in the backup snapshot. Each script in `hl1-io.backup.scripts` is run before rsnapshot takes the snapshot, with output written to `outpath` relative to the backup root.

---

## Monitoring Client

**Source:** `base-system/monitoring.nix`

When `hl1-io.monitoring.client.enable = true` (default), each Linux node runs [Promtail](https://grafana.com/docs/loki/latest/send-data/promtail/) to ship logs to the central Loki instance.

### Log Sources

- **systemd/journald** — all journal entries, parsed as JSON
- **Docker containers** — container logs (requires non-rootless Docker) <!-- TODO: Confirm whether rootless Docker is supported or not -->

### Loki Endpoint

Logs are sent to:
```
http://loki.services.c.${domains.primary}:3100
```

This resolves via Consul DNS when the node is a Consul client.

---

## File Transfers

**Source:** `base-system/file-transfers.nix`

Two Fish shell functions for transferring files to/from the master node using [socat](http://www.dest-unreach.org/socat/) and [age](https://age-encryption.org/) encryption.

| Function | Description |
|----------|-------------|
| `send-file <path>` | Encrypts and sends a file to the master node |
| `receive-files` | Receives and decrypts files from the master node |

The master node is defined by `hl1-io.master`.

---

## Fish Shell Workspace System

**Source:** `base-system/fish-configuration.nix`, `base-system/workspaces.nix`

The base system ships a workspace-aware Fish shell function system. Functions are automatically loaded and unloaded as you navigate between project directories.

### How It Works

1. When you `cd` into a directory, Fish checks if a workspace is configured for that path
2. If a matching workspace is found, its functions are sourced into the current shell
3. When you leave the directory, those functions are unloaded

### Workspaces

Workspaces are defined in `base-system/workspaces.nix` and map directory paths to Fish function sets from `base-system/scripts/`.

<!-- TODO: Document the specific workspaces and functions available. These are likely user-specific and may need to be described by the repository owner. -->

### `inject-fish-functions`

The `inject-fish-functions` flake output (`hl1-lib.inject-fish-functions`) can be imported as a NixOS module to install the workspace function system on a node without the full `personas.base`:

```nix
imports = [ hl1-lib.inject-fish-functions ];
```

### `print_banner` Function

A `print_banner <text>` function is available for styled console output in scripts. It renders text with visual decoration for readability.
