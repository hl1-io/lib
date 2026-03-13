# hl1-io/lib — NixOS Configuration Library

> **AI Disclosure:** This documentation was written by an AI assistant and may contain errors or inaccuracies. Please verify any configuration options against the source code before use. Items marked `<!-- TODO -->` require human review.

## Overview

`hl1-io/lib` is a modular NixOS configuration library for managing distributed infrastructure. It provides:

- **Option definitions** — a unified `hl1-io.*` namespace for cluster-wide settings
- **Personas** — role-based NixOS module bundles (ingress, vault, consul, nomad, etc.)
- **Base system modules** — shared package sets, shell configuration, backups, and monitoring
- **Boot method helpers** — BIOS, UEFI, and Raspberry Pi 4 boot configurations
- **Library functions (`hlib`)** — helpers for secret retrieval and assertions

The library is designed for use with [Colmena](https://github.com/zhaofengli/colmena) for multi-node deployments, though individual modules can be imported into any NixOS configuration.

---

## Quick Start

### Prerequisites

- NixOS with [Nix Flakes](https://nixos.wiki/wiki/Flakes) enabled
- [Colmena](https://github.com/zhaofengli/colmena) (for multi-node deployments)
- [gopass](https://github.com/gopasspw/gopass) (for secret management)

### Adding the Library as a Flake Input

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hl1-lib.url = "git+ssh://git@github.com/hl1-io/lib";
  };

  outputs = { nixpkgs, hl1-lib, ... }: {
    # Your configuration here
  };
}
```

### Minimal Host Configuration

```nix
# colmena configuration example
{
  meta = hl1-lib.colmena.meta;

  defaults = { ... }: {
    imports = [
      hl1-lib.lib               # Injects hl1-io options + hlib
      hl1-lib.personas.base     # Shared package set and defaults
      hl1-lib.personas.linux    # Linux-specific settings
    ];

    hl1-io = {
      master        = "my-control-node";
      cluster-label = "prod";
      domains.primary = "myorg.example.com";

      profile = {
        givenName  = "Jane";
        familyName = "Doe";
        username   = "jdoe";
        email      = "jane@myorg.example.com";
      };
    };
  };

  my-node = { name, nodes, ... }: {
    deployment.targetHost = "my-node.myorg.example.com";
    imports = [ hl1-lib.boot.uefi ];
    hl1-io.node-meta.expected-fqdn = "my-node.myorg.example.com";
  };
}
```

---

## Library Structure

| Path | Purpose |
|------|---------|
| `flake.nix` | Flake entry point; exports all outputs |
| `lib/` | Option definitions and helper modules |
| `base-system/` | Shared OS configuration (packages, shell, backups, monitoring) |
| `boot-methods/` | Boot loader configurations |
| `personas/` | Role-based service configurations |

### Flake Outputs Reference

| Output | Description |
|--------|-------------|
| `lib` | Main module — imports all `hl1-io.*` option definitions and injects `hlib` |
| `personas.base` | Common packages and home-manager setup |
| `personas.linux` | Linux-specific config (SSH, users, NFS) |
| `personas.darwin` | macOS-specific config (fonts, users) |
| `personas.consul.client` | Consul service discovery client |
| `personas.consul.server` | Consul server with DNS |
| `personas.nomad.client` | Nomad compute client |
| `personas.nomad.server` | Nomad scheduler server |
| `personas.ingress` | Traefik reverse proxy / ingress controller |
| `personas.vault` | HashiCorp Vault secret management server |
| `personas.certificate-authority` | Internal certificate authority |
| `personas.monitoring-sink` | Observability backend (Loki + Grafana + TimescaleDB) |
| `personas.mailserver` | Email server (via simple-nixos-mailserver) |
| `personas.object-storage` | S3-compatible object storage |
| `personas.idp` | Identity provider |
| `personas.tailscale-node` | Tailscale VPN node |
| `personas.bastion` | SSH bastion / jump host |
| `personas.workstation` | Developer workstation |
| `personas.workstation-user` | Workstation user home-manager setup |
| `personas.rustdesk.server` | RustDesk remote desktop server |
| `personas.rustdesk.relay` | RustDesk relay node |
| `personas.kiosk.retro` | Retro display kiosk |
| `personas.llm` | Large language model serving node |
| `boot.bios` | GRUB BIOS boot configuration |
| `boot.uefi` | systemd-boot EFI configuration |
| `boot.rpi` | Raspberry Pi 4 kernel and bootloader |
| `lang.javascript` | JavaScript/Node.js development packages |
| `lang.rust` | Rust development packages |
| `lang.go` | Go development packages |
| `inject-fish-functions` | Fish shell workspace function system |
| `colmena.meta` | Colmena meta block (x86_64-linux nixpkgs) |
| `options` | NixOS options export for nixd language server autocomplete |

---

## Documentation Index

- [Configuration Reference](./configuration-reference.md) — All `hl1-io.*` options
- [Personas](./personas.md) — Role-based configuration modules
- [Base System](./base-system.md) — Shared packages, shell, backups, and monitoring
- [Boot Methods](./boot-methods.md) — Boot loader configurations
- [Library Functions](./library-functions.md) — `hlib` helper functions

---

## Dependencies

| Input | Pinned To | Purpose |
|-------|-----------|---------|
| `nixpkgs` | `nixos-unstable` | Primary package set |
| `nixpkgs-stable` | `nixos-25.05` | Stable packages (used by home-manager) |
| `home-manager` | `release-25.05` | User environment management |
| `simple-nixos-mailserver` | `master` | Mail server module |

---

## License

MIT © 2026 hl1-io
