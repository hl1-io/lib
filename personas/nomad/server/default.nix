{ config, pkgs, ... }:
{
  hl1-io.node-meta.personas = [ "nomad-server" ];
  services.nomad = {
    package = pkgs.nomad_1_10;
    enable = true;
    dropPrivileges = true;
    settings =
      let
        domain = config.hl1-io.domains.primary;
      in
      {
        bind_addr = "0.0.0.0";
        server = {
          enabled = true;
          bootstrap_expect = 1;
        };
        acl = {
          enabled = config.hl1-io.nomad.acl-enabled;
        };
        datacenter = config.hl1-io.datacenter;

        client = {
          enabled = false;
        };
        vault = {
          enabled = true;
          address = "https://vault.${domain}";
        };
        consul = {
          address = "127.0.0.1:8500";
        };
        ui = {
          enabled = true;
          consul = {
            ui_url = "https://consul.${domain}";
          };
          vault = {
            ui_url = "https://consul.${domain}";
          };
        };

        telemetry = {
          publish_allocation_metrics = true;
          publish_node_metrics = true;
          prometheus_metrics = true;
        };
      };
  };

  systemd.services.nomad.serviceConfig = {
    EnvironmentFile = "/etc/nomad.d/nomad.env";
  };

  environment.etc."nomad.d/nomad.env" = {
    user = "nomad";
    group = "nomad";
    mode = "400";
    text = "";
  };

  networking.firewall.allowedTCPPortRanges = [
    {
      from = 4646;
      to = 4648;
    }
  ];

  hl1-io.consul.services."nomad-ui" = {
    enable = true;
    label = "Nomad UI";
    port = 4646;
    subdomain = "nomad";
  };

  systemd.services.nomad.after = [ "network-online.target" ];

  hl1-io.backup.paths = [ "/var/lib/nomad/server" ];

  environment.systemPackages = with pkgs; [ nomad-pack ];
}
