# Library Functions (`hlib`)

> **AI Disclosure:** This documentation was written by an AI assistant and may contain errors or inaccuracies. Please verify any configuration options against the source code before use. Items marked `<!-- TODO -->` require human review.

The library exposes a set of helper functions under the `hlib` argument, available in any module that imports `hl1-lib.lib`.

`hlib` is injected as a special module argument via `_module.args.hlib` and can be used directly in module expressions:

```nix
{ hlib, config, ... }: {
  # Use hlib here
}
```

---

## Secret Management

The library uses [gopass](https://github.com/gopasspw/gopass) (a pass-compatible password manager) for all secret retrieval. The helper functions below produce command arrays suitable for use in Colmena's `deployment.keys.*.keyCommand` and NixOS module options that accept a `passwordCommand`.

### `hlib.readPass`

Retrieves a secret value from gopass.

**Signature:**
```
readPass :: string -> list of string
```

**Arguments:**
- `password` — the gopass path to the secret (e.g. `"mail/jane"`)

**Returns:** A command list `[ "gopass" "<password>" ]`

**Usage:**

```nix
deployment.keys."my-secret" = {
  keyCommand = hlib.readPass "services/my-app/api-key";
};
```

```nix
hl1-io.mail.account.jane = {
  passwordCommand = hlib.readPass "mail/jane";
};
```

---

### `hlib.readPassAsEnv`

Retrieves a secret from gopass and formats it as a shell environment variable assignment (`KEY=value`). Useful for populating `.env` files or systemd `EnvironmentFile`s.

**Signature:**
```
readPassAsEnv :: string -> string -> list of string
```

**Arguments:**
- `env` — the environment variable name (e.g. `"DO_AUTH_TOKEN"`)
- `password` — the gopass path to the secret

**Returns:** A command list `[ "sh" "-c" "echo <env>=\`gopass <password>\`" ]`

**Usage:**

```nix
deployment.keys."app.env" = {
  keyCommand = hlib.readPassAsEnv "API_KEY" "services/my-app/api-key";
};
```

The resulting file will contain:
```
API_KEY=<secret-value>
```

---

## Assertions

### `hlib.nonEmpty`

Creates a NixOS assertion that verifies a string is non-empty.

**Signature:**
```
nonEmpty :: string -> { assertion: bool; message: string }
```

**Arguments:**
- `value` — the string to check

**Returns:** A NixOS assertion attrset suitable for inclusion in `config.assertions`

**Usage:**

```nix
{ config, hlib, ... }: {
  assertions = [
    (hlib.nonEmpty config.hl1-io.domains.primary)
    (hlib.nonEmpty config.hl1-io.profile.username)
  ];
}
```

---

## Advanced: Consul Service Registration

**Source:** `lib/consul-service.nix`

The `consul-service` helper module is used internally by the library to generate Consul service definition files with Traefik routing tags. It reads from `hl1-io.consul.services` and produces JSON files that Consul picks up for service registration and health checking.

This is used automatically when the `consul.client` persona is applied — you do not need to call it directly.

---

## Advanced: Vault Agent Templates

**Source:** `lib/vault-agent.nix`

The vault agent helper generates a `vault-agent` systemd service for each entry in `hl1-io.vault-agency`. Each agent:

1. Authenticates to Vault using [AppRole](https://developer.hashicorp.com/vault/docs/auth/approle)
2. Renders the configured template using Vault's [template engine](https://developer.hashicorp.com/vault/docs/agent-and-proxy/agent/template)
3. Writes the rendered content to `destination`
4. Optionally restarts a systemd `unit` after re-rendering

See the [Vault section of the Configuration Reference](./configuration-reference.md#vault) for the full option set.

---

## Advanced: Systemd Path Watchers

**Source:** `lib/systemd-watch.nix`

The systemd-watch helper generates `systemd.path` units for each entry in `hl1-io.systemd.watch`. When a watched file changes, the corresponding systemd unit is restarted.

See the [Systemd Watchers section of the Configuration Reference](./configuration-reference.md#systemd-watchers) for the full option set.

---

## Accessing `hlib` Outside Colmena

If you are building a standalone NixOS configuration (not using Colmena), `hlib` is still available as long as you import `hl1-lib.lib`:

```nix
# flake.nix
{
  nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      hl1-lib.lib   # Makes hlib available as a module argument
      ./configuration.nix
    ];
  };
}
```

```nix
# configuration.nix
{ hlib, ... }: {
  deployment.keys."my-key" = {
    keyCommand = hlib.readPass "my/secret";
  };
}
```

> **Note:** `hlib.readPass` and `hlib.readPassAsEnv` produce command lists that are executed at deployment time. They require `gopass` to be installed and configured on the **deploying machine** (not the target node).
