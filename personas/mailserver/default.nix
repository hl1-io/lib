{ hlib, config, ... }: {
  imports = [ ./accounts.nix ];
  config = {
    hl1-io.node-meta.personas = [ "mailserver" ];
    mailserver.enable = true;
    mailserver.domains = [ config.hl1-io.domains.primary ]
      ++ config.hl1-io.mail.additionalDomains;
    mailserver.fqdn = config.hl1-io.mail.fqdn;

    mailserver.certificateScheme = "manual";
    mailserver.certificateFile = "/etc/mail.d/mail.crt";
    mailserver.keyFile = "/etc/mail.d/mail.pem";

    # Disable kresd for now, this breaks internal DNS Resolution
    mailserver.localDnsResolver = false;

    hl1-io.backup.paths = [ "/var/vmail" "/var/dkim" ];

    hl1-io.ingress.requestedEntrypoints = {
      "imap" = {
        port = 143;
        public = true;
      };
      "imap-ssl" = {
        port = 993;
        public = true;
      };
      "smtp" = {
        port = 25;
        public = true;
      };
      "smtp-starttls" = {
        port = 587;
        public = true;
      };
      "smtp-ssl" = {
        port = 465;
        public = true;
      };
    };

    hl1-io.consul.services = {
      "mailserver-imap" = {
        enable = true;
        label = "Mailserver IMAP";
        port = 143;
        entrypoint = "imap";
        routerType = "tcp";
        address = config.hl1-io.node-meta.expected-fqdn;
      };
      "mailserver-imap-ssl" = {
        enable = true;
        label = "Mailserver IMAP (SSL)";
        port = 993;
        entrypoint = "imap-ssl";
        routerType = "tcp";
        address = config.hl1-io.node-meta.expected-fqdn;
      };
      "mailserver-smtp" = {
        enable = true;
        label = "Mailserver SMTP";
        port = 25;
        entrypoint = "smtp";
        routerType = "tcp";
        address = config.hl1-io.node-meta.expected-fqdn;
      };
      "mailserver-smtp-starttls" = {
        enable = true;
        label = "Mailserver SMTP (STARTTLS)";
        port = 587;
        entrypoint = "smtp-starttls";
        routerType = "tcp";
        address = config.hl1-io.node-meta.expected-fqdn;
      };
      "mailserver-smtp-ssl" = {
        enable = true;
        label = "Mailserver SMTP (SSL)";
        port = 465;
        entrypoint = "smtp-ssl";
        routerType = "tcp";
        address = config.hl1-io.node-meta.expected-fqdn;
      };
    };

    deployment.keys."mail-cert" = {
      destDir = "/etc/mail.d";
      name = "mail.crt";

      keyCommand =
        hlib.readPass "certs/${config.hl1-io.mail.fqdn}.crt";
    };
    deployment.keys."mail-key" = {
      destDir = "/etc/mail.d";
      name = "mail.pem";

      keyCommand =
        hlib.readPass "certs/${config.hl1-io.mail.fqdn}.pem";
    };
  };
}
