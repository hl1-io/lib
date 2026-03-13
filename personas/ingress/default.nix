{
  hlib,
  config,
  nodes,
  lib,
  ...
}:
let
  allRequestedEntrypoints =
    with lib;
    let
      allEntrypoints = flatten (
        mapAttrsToList (
          nodeName: nodeConfig:
          mapAttrsToList (name: value: { inherit name value nodeName; }) (
            nodeConfig.config.hl1-io.ingress.requestedEntrypoints or { }
          )
        ) nodes
      );

      groupedEntrypoints = groupBy (e: e.name) allEntrypoints;

      mergedEntrypoints = mapAttrs (name: entries: (head entries).value) groupedEntrypoints;
    in
    mergedEntrypoints;
in
{
  hl1-io.node-meta.personas = [ "ingress" ];

  services.traefik.enable = true;
  networking.firewall.allowedTCPPorts = [
    80
    443
    4443
    22442
  ]
  ++ (lib.mapAttrsToList (_: entry: entry.port) allRequestedEntrypoints);

  systemd.tmpfiles.rules = [
    "d /etc/traefik.dyn 0755 traefik traefik"
    "d /etc/traefik 0755 traefik traefik"
  ];
  systemd.services.traefik.serviceConfig = {
    ReadWritePaths = [
      "/etc/traefik.dyn"
      "/etc/traefik"
    ];
  };

  deployment.keys."traefik.env" = {
    permissions = "0400";
    user = "traefik";
    group = "traefik";
    keyCommand = hlib.readPassAsEnv "DO_AUTH_TOKEN" "digitalocean-token";
  };

  services.traefik.environmentFiles = [ "/run/keys/traefik.env" ];

  services.traefik.staticConfigOptions = {
    log = {
      level = "DEBUG";
    };

    # TODO: make this more configurable
    certificatesResolvers.lets-encrypt-dns.acme = {
      email = config.hl1-io.profile.email;
      storage = "/etc/traefik/acme.json";
      dnsChallenge = {
        provider = "digitalocean";
        delayBeforeCheck = 0;
      };
    };

    entryPoints = lib.mkMerge [
      {
        http = {
          address = ":80";
          http = {
            # middlewares = [ "private-domain-ipwhitelist@file" ];
            redirections = {
              entryPoint = {
                to = "https";
                scheme = "https";
                permanent = true;
              };
            };
          };
        };
        https = {
          address = ":443";
          http = {
            tls = true;
            # middlewares = [ "private-domain-ipwhitelist@file" ];
          };
        };
        dbs = {
          address = ":4443";
        };
        # This is special because gitea runs in nomad
        gitea-ssh = {
          address = ":22442";
        };
      }
      (lib.mapAttrs (_: entry: { address = ":${toString entry.port}"; }) allRequestedEntrypoints)
    ];

    providers = {
      file = {
        directory = "/etc/traefik.dyn";
        watch = true;
      };
      consulCatalog = with config; {
        watch = true;
        exposedByDefault = false;
        defaultRule = "Host(`{{ normalize .Name }}.${hl1-io.domains.primary}`)";
        endpoint = {
          address = "127.0.0.1:8500";
        };
      };
    };
  };

  deployment.keys = {
    "ingress.crt" = {
      permissions = "0400";
      destDir = "/etc/traefik.dyn";
      user = "traefik";
      group = "traefik";
      keyCommand = hlib.readPass "certs/wildcard/${config.hl1-io.domains.primary}.crt";
    };
    "ingress.pem" = {
      permissions = "0400";
      destDir = "/etc/traefik.dyn";
      user = "traefik";
      group = "traefik";
      keyCommand = hlib.readPass "certs/wildcard/${config.hl1-io.domains.primary}.pem";
    };
  };

  environment.etc."/traefik.dyn/certs.yaml" = {
    user = "traefik";
    group = "traefik";
    mode = "400";
    text = ''
      tls:
        certificates:
          - certFile: /etc/traefik.dyn/ingress.crt
            keyFile: /etc/traefik.dyn/ingress.pem
    '';
  };

  environment.etc."/traefik.dyn/alpn.yaml" = {
    user = "traefik";
    group = "traefik";
    mode = "400";
    text = ''
      tls:
        options:
          default:
            alpnProtocols:
              - http/1.1
              - h2
              - postgresql
              - acme-tls/1
    '';
  };

  environment.etc."/traefik.dyn/secure.yaml" = {
    # TODO: Make this more configurable
    text = ''
      # traefik.yml
      middlewares:
        private-access-only:
          ipWhiteList:
            sourceRange:
              - "192.168.0.0/16" # LAN
              - "100.64.0.0/10"  # Tailscale
              # - "10.0.0.0/8"   # VLANs? Not sure if we want to enable this
    '';
  };

  # TODO: Identify our Auth setup here
  # environment.etc."/etc/traefik.dyn/dashboard.yaml" = {

  # };
}
