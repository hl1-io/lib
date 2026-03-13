{
  config,
  hlib,
  pkgs-legacy,
  ...
}:
let
  port = 8987;
in
{
  # environment.systemPackages = [ pkgs-legacy.kanidm ];
  hl1-io.node-meta.personas = [ "idp" ];
  networking.firewall.allowedTCPPorts = [
    port
    636
  ];

  deployment.keys = {
    "kanidm.crt" = {
      permissions = "0400";
      destDir = "/etc/kanidm";
      user = "kanidm";
      group = "kanidm";
      keyCommand =
        hlib.readPass "certs/auth.${config.hl1-io.domains.primary}.crt";
    };
    "kanidm.pem" = {
      permissions = "0400";
      destDir = "/etc/kanidm";
      user = "kanidm";
      group = "kanidm";
      keyCommand =
        hlib.readPass "certs/auth.${config.hl1-io.domains.primary}.pem";
    };
  };

  services.kanidm = {
    package = pkgs-legacy.kanidm;
    enableServer = true;
    serverSettings = {
      bindaddress = "0.0.0.0:${toString port}";
      domain = "auth.${config.hl1-io.domains.primary}";
      origin = "https://auth.${config.hl1-io.domains.primary}";
      tls_chain = "/etc/kanidm/kanidm.crt";
      tls_key = "/etc/kanidm/kanidm.pem";
      ldapbindaddress = "0.0.0.0:636";
    };
  };

  hl1-io.ingress.requestedEntrypoints = {
    ldap = {
      port = 636;
      public = false;
    };
  };

  hl1-io.consul.services."kanidm" = {
    enable = true;
    label = "kanidm";
    port = port;
    subdomain = "auth";
    httpsBackend = true;
  };
  hl1-io.consul.services."kanidm-ldap" = {
    enable = true;
    label = "kanidm (ldap)";
    port = 636;
    entrypoint = "ldap";
    routerType = "tcp";
  };

  hl1-io.backup.paths = [
    "/var/lib/kanidm"
  ];

  # TODO: Set up a local pass instance (can we forward a key somehow?)
  # TODO: Configure the admin, idm_admin accounts and save passwords into pass
  # TODO: Add some 'hl1-io.kanidm.oauth' / 'hl1-io.kanidm.user' modules

  # TODO: The above will likely end up being a series of systemd services to create /
  #       maintain the oauth and users. We could possibly even sync the values to vault
  #       once created - which would then make `vault-agent` more useful for getting the
  #       OAuth2 credentials automatically
}
