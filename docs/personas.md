# Personas

> **AI Disclosure:** This documentation was written by an AI assistant and may contain errors or inaccuracies. Please verify any configuration options against the source code before use. Items marked `<!-- TODO -->` require human review.

Personas are pre-packaged NixOS module bundles that configure a node for a specific role. Importing a persona activates the relevant services and registers the node in `hl1-io.node-meta.personas` for discovery by other cluster members.

Multiple personas can be applied to the same node.

## Importing a Persona

```nix
# In your colmena or nixosConfiguration:
imports = [
  hl1-lib.personas.base
  hl1-lib.personas.linux
  hl1-lib.personas.consul.client
  hl1-lib.personas.ingress
];
```

---

## Base System Personas

These are not "service personas" but foundational system configurations. See [Base System](./base-system.md) for full details.

| Output | Description |
|--------|-------------|
| `personas.base` | Common packages, shell aliases, home-manager setup |
| `personas.linux` | Linux-specific: SSH server, user creation, NFS, backups |
| `personas.darwin` | macOS-specific: Nerd Fonts, user creation |

---

## Service Personas

### Consul

#### `personas.consul.client`

Registers the node as a Consul agent that joins the existing cluster.

- Runs the Consul agent in client mode
- Connects to the local Consul server via service discovery

**Relevant options:**
- `hl1-io.consul.acl-enabled` — enable ACL enforcement
- `hl1-io.consul.services` — services to register with the Consul catalog

---

#### `personas.consul.server`

Configures the node as a Consul server (cluster coordinator).

- Bootstraps or joins the Consul server quorum
- Enables the Consul web UI
- Runs a DNS resolver on port 53 for `.consul` domain lookups

**Relevant options:**
- `hl1-io.consul.server.host` — bind address (default: `0.0.0.0`)
- `hl1-io.consul.acl-enabled` — enable ACL enforcement
- `hl1-io.datacenter` — datacenter/cluster name shown in the UI

---

### Nomad

#### `personas.nomad.client`

Configures the node as a Nomad compute client that accepts and runs workloads.

**Relevant options:**
- `hl1-io.nomad.acl-enabled` — enable ACL enforcement
- `hl1-io.nomad.pool` — node pool assignment (default: `"default"`)

---

#### `personas.nomad.server`

Configures the node as a Nomad scheduler server.

**Relevant options:**
- `hl1-io.nomad.acl-enabled` — enable ACL enforcement

---

### Ingress

#### `personas.ingress`

Deploys [Traefik](https://traefik.io/) as the cluster reverse proxy and ingress controller.

**Default open ports:**

| Port | Purpose |
|------|---------|
| `80` | HTTP (auto-redirects to HTTPS) |
| `443` | HTTPS |
| `4443` | Database / TLS passthrough entrypoint (`dbs`) |
| `22442` | Gitea SSH passthrough (`gitea-ssh`) |

Additional ports are opened for any `hl1-io.ingress.requestedEntrypoints`.

**Features:**
- Automatic TLS via Let's Encrypt DNS challenge (DigitalOcean provider) <!-- TODO: This is hardcoded to DigitalOcean. Verify if this is configurable. -->
- Wildcard certificate loaded from gopass (`certs/wildcard/${domains.primary}.crt` and `.pem`)
- Dynamic configuration from `/etc/traefik.dyn/` (watched for live reloading)
- Consul Catalog integration — services registered in Consul are automatically exposed
- Default routing rule: `Host(\`{{ normalize .Name }}.${domains.primary}\`)`
- IP whitelist middleware for private access: `192.168.0.0/16` and `100.64.0.0/10` (Tailscale)

**gopass secrets required:**
- `digitalocean-token` — DigitalOcean API token for ACME DNS challenge
- `certs/wildcard/${domains.primary}.crt` — wildcard TLS certificate
- `certs/wildcard/${domains.primary}.pem` — wildcard TLS private key

**Relevant options:**
- `hl1-io.domains.primary` — used as the default routing domain
- `hl1-io.ingress.requestedEntrypoints` — additional Traefik entrypoints
- `hl1-io.profile.email` — email address for ACME certificate registration

---

### Vault

#### `personas.vault`

Deploys [HashiCorp Vault](https://www.vaultproject.io/) as the cluster secret management server.

- Uses Consul as the storage backend
- Listens on port `4444` by default

**Relevant options:**
- `hl1-io.vault.host` — bind address (default: `0.0.0.0`)
- `hl1-io.vault.port` — listen port (default: `4444`)

---

<!-- TODO: Document personas.vault-automated once the automated unsealing implementation is complete. The source contains TODO notes about this persona. -->

### Certificate Authority

#### `personas.certificate-authority`

Sets up an internal certificate authority for the cluster.

<!-- TODO: Add implementation details for the certificate-authority persona. The source code was not fully explored for this persona. -->

---

### Monitoring

#### `personas.monitoring-sink`

Deploys the central observability backend:

- **[Loki](https://grafana.com/oss/loki/)** — log aggregation, receiving from Promtail clients
- **[TimescaleDB](https://www.timescale.com/)** (PostgreSQL extension) — time-series metrics storage
- **[Grafana](https://grafana.com/)** — dashboards and visualization (enabled by default)

Logs are received from nodes running `personas.linux` (which enables Promtail via `base-system/monitoring.nix`).

Loki is accessible at `loki.services.c.${domains.primary}:3100` from within the cluster.

**Relevant options:**
- `hl1-io.monitoring.sink.enableGrafana` — toggle Grafana (default: `true`)
- `hl1-io.monitoring.sink.port` — Grafana port (default: `6543`)
- `hl1-io.monitoring.sink.host` — bind address (default: `0.0.0.0`)
- `hl1-io.monitoring.sink.pgadmin.enable` — enable pgAdmin (default: `false`)

---

### Mail Server

#### `personas.mailserver`

Deploys a complete email server using [simple-nixos-mailserver](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver).

**Relevant options:**
- `hl1-io.mail.fqdn` — mail server FQDN (default: `mail.${domains.primary}`)
- `hl1-io.mail.additionalDomains` — additional mail domains
- `hl1-io.mail.account` — email account definitions with password commands

---

### Object Storage

#### `personas.object-storage`

Deploys an S3-compatible object storage service.

<!-- TODO: Add implementation details for the object-storage persona. -->

---

### Identity Provider

#### `personas.idp`

Deploys an identity provider for cluster authentication.

<!-- TODO: Add implementation details for the idp persona. This may be Kanidm based on references in the source code. -->

---

### Tailscale

#### `personas.tailscale-node`

Connects the node to a [Tailscale](https://tailscale.com/) VPN mesh network.

<!-- TODO: Add implementation details and any required auth key configuration. -->

---

### Bastion

#### `personas.bastion`

Deploys [sshportal](https://github.com/moul/sshportal) as an SSH bastion / jump host.

- Listens on port `2222` by default (configurable)

**Relevant options:**
- `hl1-io.bastion.port` — SSH bastion port (default: `2222`)

---

### RustDesk

#### `personas.rustdesk.server`

Deploys the [RustDesk](https://rustdesk.com/) ID/rendezvous server for self-hosted remote desktop.

---

#### `personas.rustdesk.relay`

Deploys the RustDesk HBBS relay server.

---

### Virtualization

#### `personas.virt`

Configures the node as a KVM/QEMU virtualization host.

- Enables `libvirtd` and QEMU/KVM packages
- <!-- TODO: Verify exact packages and kernel modules enabled -->

---

### LLM

#### `personas.llm`

Configures the node for large language model serving.

<!-- TODO: Add implementation details for the llm persona. -->

---

### Kiosk

#### `personas.kiosk.retro`

Configures the node as a display kiosk with a retro aesthetic.

<!-- TODO: This persona has known TODO notes in the source about display setup being incomplete. Verify before use. -->

---

### Workstation

#### `personas.workstation`

Configures the node as a developer workstation.

**Installed tooling (above base packages):**
- Container: `docker` (rootless mode via `base-system/linux.nix`)
- Deployment: `colmena`
- Secrets: `gopass`
- Infrastructure: <!-- TODO: Verify if terraform/opentofu is included -->
- Language servers: `terraform-ls`

**Language package sets** (imported separately via `hl1-lib.lang.*`):

| Output | Packages |
|--------|---------|
| `lang.javascript` | Node.js, npm, yarn, and related tools |
| `lang.rust` | Rust toolchain, cargo tools |
| `lang.go` | Go toolchain and tools |

#### `personas.workstation-user`

Home-manager configuration for the workstation user. Includes SSH configuration.

```nix
imports = [
  hl1-lib.personas.workstation
  hl1-lib.personas.workstation-user
];
```

---

## Applying Multiple Personas

A single node can have multiple personas. The node-meta personas list is populated automatically:

```nix
# Example: a node that acts as both ingress and monitoring sink
my-gateway = { ... }: {
  imports = [
    hl1-lib.personas.base
    hl1-lib.personas.linux
    hl1-lib.personas.ingress
    hl1-lib.personas.monitoring-sink
  ];
  hl1-io.node-meta.expected-fqdn = "gateway.myorg.com";
};
```

After applying, `hl1-io.node-meta.personas` will contain `[ "ingress" "monitoring-sink" ]`, which other cluster members can use for service discovery.
