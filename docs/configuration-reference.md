# Configuration Reference

> **AI Disclosure:** This documentation was written by an AI assistant and may contain errors or inaccuracies. Please verify any configuration options against the source code before use. Items marked `<!-- TODO -->` require human review.

All options in this library live under the `hl1-io` attribute namespace. They are made available by importing `hl1-lib.lib` into your NixOS module.

---

## Table of Contents

- [Top-Level Options](#top-level-options)
- [Backup (`hl1-io.backup`)](#backup)
- [Bastion (`hl1-io.bastion`)](#bastion)
- [Consul (`hl1-io.consul`)](#consul)
- [Domains (`hl1-io.domains`)](#domains)
- [Ingress (`hl1-io.ingress`)](#ingress)
- [iSCSI (`hl1-io.iscsi`)](#iscsi)
- [Mail (`hl1-io.mail`)](#mail)
- [Monitoring (`hl1-io.monitoring`)](#monitoring)
- [Node Metadata (`hl1-io.node-meta`)](#node-metadata)
- [Nomad (`hl1-io.nomad`)](#nomad)
- [Profile (`hl1-io.profile`)](#profile)
- [Systemd Watchers (`hl1-io.systemd`)](#systemd-watchers)
- [Vault (`hl1-io.vault` and `hl1-io.vault-agency`)](#vault)

---

## Top-Level Options

These options live directly under `hl1-io.*`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.datacenter` | `string` | `"hl1-io"` | Cosmetic name for the cluster; used in Consul and Nomad metadata |
| `hl1-io.master` | `string` | *(required)* | Hostname of the master/control node; used for file transfers |
| `hl1-io.cluster-label` | `string` | `"-"` | Short identifier for the cluster; appended to backup names |
| `hl1-io.hliac-location` | `string` | `"git+ssh://git@github.com/hl1-io/lib"` | Git URL of this library; used when nodes need to reference the library source |

### Example

```nix
hl1-io = {
  datacenter    = "home-lab";
  master        = "control01";
  cluster-label = "prod";
};
```

---

## Backup

**Source:** `lib/option-definitions/backup.nix`

Controls rsnapshot-based backup behaviour. See [Base System — Backups](./base-system.md#backups) for implementation details.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.backup.nfs` | `string \| null` | `null` | NFS mount path to use as the backup destination. If `null`, backups are stored locally |
| `hl1-io.backup.paths` | `list of string` | `[]` | Additional filesystem paths to include in backups |
| `hl1-io.backup.scripts` | `list of script` | `[]` | Scripts that produce data to be backed up (see below) |
| `hl1-io.backup.dailyRetention` | `int` | `365` | Number of daily backup snapshots to retain |

### `backup.scripts` Sub-Options

Each entry in `hl1-io.backup.scripts` is a submodule with:

| Option | Type | Description |
|--------|------|-------------|
| `script` | `path` | Path to the script file to run before backup |
| `outpath` | `string` | Destination path relative to the backup root where the script's output is stored |

### Example

```nix
hl1-io.backup = {
  nfs            = "/mnt/backup-nfs";
  dailyRetention = 180;
  paths          = [ "/var/lib/myapp" ];
  scripts = [
    {
      script  = ./scripts/dump-db.sh;
      outpath = "database-dumps";
    }
  ];
};
```

---

## Bastion

**Source:** `lib/option-definitions/bastion.nix`

Options for the SSH bastion / jump host persona. See [Personas — Bastion](./personas.md#bastion).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.bastion.port` | `int` | `2222` | TCP port the SSH bastion listens on |

---

## Consul

**Source:** `lib/option-definitions/consul.nix`

Controls service discovery integration with [HashiCorp Consul](https://www.consul.io/).

### Server Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.consul.server.host` | `string` | `"0.0.0.0"` | Address the Consul server binds to |
| `hl1-io.consul.acl-enabled` | `bool` | `false` | Enable Consul ACL system |

### Service Registration (`hl1-io.consul.services`)

`hl1-io.consul.services` is an attribute set of service definitions. Each key is a unique service ID and each value is a submodule:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Whether this service registration is active |
| `label` | `string` | *(required)* | Service label / ID. Services with identical labels are load-balanced by Consul |
| `port` | `int` | *(required)* | Port the service listens on |
| `subdomain` | `string` | `""` | DNS subdomain prefix used for Traefik routing |
| `httpsBackend` | `bool` | `false` | Set to `true` if the backend itself serves HTTPS (e.g. Kanidm) |
| `routerType` | `enum` | `"http"` | Traefik router type: `"http"`, `"tcp-sni"`, or `"tcp"` (see below) |
| `address` | `string` | `""` | Bind address for this service |
| `entrypoint` | `string` | `"https"` | Traefik entrypoint name to attach this service to |
| `tls` | `bool` | `false` | Enable TLS for TCP services (HTTP services always use TLS) |

#### `routerType` Values

| Value | Use Case |
|-------|---------|
| `"http"` | Standard web/HTTP service |
| `"tcp-sni"` | TCP service with TLS that supports SNI routing (e.g. PostgreSQL with TLS) |
| `"tcp"` | Raw TCP service without SNI (e.g. Gitea SSH) |

> **Note:** Consul service IDs (the attribute key) must not contain spaces — this is enforced by an assertion.

### Example

```nix
hl1-io.consul.services = {
  my-web-app = {
    enable    = true;
    label     = "my-web-app";
    port      = 8080;
    subdomain = "app";
  };

  my-db = {
    enable      = true;
    label       = "postgres";
    port        = 5432;
    routerType  = "tcp-sni";
    entrypoint  = "dbs";
    tls         = true;
  };
};
```

---

## Domains

**Source:** `lib/option-definitions/domains.nix`

Cluster domain configuration used across services for DNS names, TLS certificates, and OAuth sessions.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.domains.primary` | `string` | `"example.com"` | Primary domain that hosts most (or all) cluster services and nodes |
| `hl1-io.domains.additional` | `list of string` | `[]` | Additional domains that may host cluster services |
| `hl1-io.domains.authDomain` | `string \| null` | `null` | Cookie domain for OAuth sessions. Usually the same as `primary`; only set this if they differ |
| `hl1-io.domains.caUrl` | `string \| null` | `null` | Override the default certificate authority URL. Defaults to `stepca.${domains.primary}` |

### Example

```nix
hl1-io.domains = {
  primary    = "myorg.com";
  additional = [ "myorg.net" ];
  # authDomain = "myorg.com";  # Only needed if different from primary
};
```

---

## Ingress

**Source:** `lib/option-definitions/ingress.nix`

Options for requesting additional Traefik entrypoints on the ingress node. Useful for exposing non-HTTP services (e.g. PostgreSQL).

> **Note:** Entrypoint names must be globally unique across all nodes. A NixOS assertion enforces this at build time.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.ingress.requestedEntrypoints` | `attrs of entrypoint` | `{}` | Additional Traefik entrypoints to expose on the ingress node |

### `requestedEntrypoints` Sub-Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `port` | `int` | *(required)* | Port number for this entrypoint |
| `public` | `bool` | `false` | Whether this entrypoint should be publicly accessible |

### Example

```nix
hl1-io.ingress.requestedEntrypoints = {
  postgres = {
    port   = 5432;
    public = false;
  };
  mqtt = {
    port   = 1883;
    public = true;
  };
};
```

---

## iSCSI

**Source:** `lib/option-definitions/iscsi.nix`

> **Note:** iSCSI mount support is partially implemented. LVM auto-detection is a known TODO in the source code.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.iscsi.defaultPortal` | `string \| null` | `null` | Default iSCSI portal address used when a mount does not specify one |
| `hl1-io.iscsi.mounts` | `attrs of mount` | `{}` | iSCSI targets to discover and mount |

### `iscsi.mounts` Sub-Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Activate this iSCSI mount |
| `portal` | `string \| null` | `null` | iSCSI portal address (overrides `defaultPortal`) |
| `target` | `string` | *(required)* | iSCSI Qualified Name (IQN) of the target |
| `mountPath` | `string` | *(required)* | Local filesystem path to mount the iSCSI block device |

---

## Mail

**Source:** `lib/option-definitions/mail.nix`

Mail server configuration. Used by the `mailserver` persona (powered by [simple-nixos-mailserver](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver)).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.mail.fqdn` | `string` | `"mail.${domains.primary}"` | Fully-qualified domain name for the mail server |
| `hl1-io.mail.additionalDomains` | `list of string` | `[]` | Additional domains to accept mail for |
| `hl1-io.mail.account` | `attrs of account` | `{}` | Email accounts to create |

### `mail.account` Sub-Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `passwordCommand` | `list of string` | *(required)* | Command to retrieve the account password (e.g. via `hlib.readPass`) |
| `domain` | `string` | `domains.primary` | Domain for this account |
| `serviceAccount` | `bool` | `false` | Mark as a service account (affects provisioning behaviour) |

### Example

```nix
hl1-io.mail = {
  additionalDomains = [ "myorg.net" ];
  account = {
    jane = {
      passwordCommand = hlib.readPass "mail/jane";
      domain         = "myorg.com";
    };
    noreply = {
      passwordCommand = hlib.readPass "mail/noreply";
      serviceAccount  = true;
    };
  };
};
```

---

## Monitoring

**Source:** `lib/option-definitions/monitoring.nix`

Monitoring stack configuration. The "sink" is the central observability server; the "client" is the per-node log shipper.

### Sink Options (central server)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.monitoring.sink.enableGrafana` | `bool` | `true` | Deploy Grafana alongside the monitoring sink |
| `hl1-io.monitoring.sink.port` | `int` | `6543` | Port Grafana listens on |
| `hl1-io.monitoring.sink.host` | `string` | `"0.0.0.0"` | Address the monitoring sink binds to |
| `hl1-io.monitoring.sink.pgadmin.enable` | `bool` | `false` | Enable pgAdmin alongside the monitoring sink |

### Client Options (per-node log shipper)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.monitoring.client.enable` | `bool` | `true` | Enable Promtail log shipping on this node |

---

## Node Metadata

**Source:** `lib/option-definitions/node-meta.nix`

Per-node identity and role tracking.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.node-meta.expected-fqdn` | `string` | `"node.example.com"` | Expected fully-qualified domain name for this node |
| `hl1-io.node-meta.personas` | `list of string` | `[]` | List of persona names applied to this node (automatically set by each persona module) |

> **Note:** `personas` is typically managed automatically by the persona modules themselves. You should not need to set it manually.

---

## Nomad

**Source:** `lib/option-definitions/nomad.nix`

Configuration for the [HashiCorp Nomad](https://www.nomadproject.io/) cluster.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.nomad.acl-enabled` | `bool` | `false` | Enable Nomad ACL system |
| `hl1-io.nomad.pool` | `string` | `"default"` | Nomad node pool name for client nodes |

---

## Profile

**Source:** `lib/option-definitions/profile.nix`

User identity information used across the system (user creation, Git config, TLS certificate email, etc.).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.profile.givenName` | `string` | `""` | User's given (first) name |
| `hl1-io.profile.familyName` | `string` | `""` | User's family (last) name |
| `hl1-io.profile.username` | `string` | `"hl1-user"` | Linux username for the primary user account |
| `hl1-io.profile.email` | `string` | `"user@example.com"` | Primary email address; used for TLS certificate registration and Git config |

### Example

```nix
hl1-io.profile = {
  givenName  = "Jane";
  familyName = "Doe";
  username   = "jdoe";
  email      = "jane@myorg.com";
};
```

---

## Systemd Watchers

**Source:** `lib/option-definitions/systemd.nix`

File watchers that automatically restart systemd units when watched files change.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.systemd.watch` | `attrs of watcher` | `{}` | Named file watcher definitions |

### `systemd.watch` Sub-Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Activate this file watcher |
| `paths` | `list of string` | *(required)* | Filesystem paths to watch for changes |
| `unit` | `string` | *(required)* | Systemd unit name to restart when a watched path changes |

### Example

```nix
hl1-io.systemd.watch = {
  restart-nginx-on-cert-change = {
    enable = true;
    paths  = [ "/etc/ssl/certs/myorg.crt" ];
    unit   = "nginx.service";
  };
};
```

---

## Vault

**Source:** `lib/option-definitions/vault.nix`

[HashiCorp Vault](https://www.vaultproject.io/) server settings and per-service agent configuration.

### Server Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hl1-io.vault.host` | `string` | `"0.0.0.0"` | Address the Vault server binds to |
| `hl1-io.vault.port` | `int` | `4444` | Port the Vault server listens on |

### Vault Agents (`hl1-io.vault-agency`)

`hl1-io.vault-agency` is an attribute set of Vault agent definitions. Each agent uses [AppRole authentication](https://developer.hashicorp.com/vault/docs/auth/approle) to render secret templates to disk, optionally restarting a systemd unit when values change.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Enable this Vault agent instance |
| `name` | `string` | `"unnamed-agent"` | Name for this agent instance (used in systemd unit naming) |
| `user` | `string` | `"root"` | System user the agent process runs as |
| `group` | `string` | `"root"` | System group the agent process runs as |
| `destination` | `string` | *(required)* | Absolute path where the rendered template will be written |
| `template` | `string` | *(required)* | Literal [Vault agent template](https://developer.hashicorp.com/vault/docs/agent-and-proxy/agent/template) content |
| `unit` | `string` | `""` | Systemd unit to restart after the template is re-rendered. Empty string disables restarts |

### Example

```nix
hl1-io.vault-agency = {
  my-app-db-creds = {
    enable      = true;
    name        = "my-app-db-creds";
    user        = "myapp";
    group       = "myapp";
    destination = "/run/myapp/db.env";
    unit        = "myapp.service";
    template    = ''
      {{ with secret "database/creds/my-role" }}
      DB_USER={{ .Data.username }}
      DB_PASS={{ .Data.password }}
      {{ end }}
    '';
  };
};
```
