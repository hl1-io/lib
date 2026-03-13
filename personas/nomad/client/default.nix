{ config, pkgs, ... }:
{
  hl1-io.node-meta.personas = [ "nomad-client" ];
  services.nomad = {
    package = pkgs.nomad_1_10;
    enable = true;
    dropPrivileges = false;
    settings =
      let
        domain = config.hl1-io.domains.primary;
      in
      {
        bind_addr = "0.0.0.0";

        server = {
          enabled = false;
        };
        datacenter = config.hl1-io.datacenter;

        client = {
          enabled = true;
          node_pool = config.hl1-io.nomad.pool;
          artifact = {
            disable_filesystem_isolation = true;
          };
        };

        consul = {
          address = "http://localhost:8500";
        };

        vault = {
          enabled = true;
          address = "https://vault.${domain}";
        };

        plugin = {
          "docker" = {
            config = {
              allow_privileged = true;
              volumes = {
                enabled = true;
              };
              gc = {
                image_delay = "24h";
              };
            };
          };
        };
      };
  };

  networking.firewall.allowedTCPPortRanges = [
    {
      from = 20000;
      to = 32000;
    }
  ];
  networking.firewall.allowedTCPPorts = [
    4646
    4647
    4648
  ];
  networking.firewall.extraCommands = "iptables -A nixos-fw -i docker0 -o docker0 -p tcp -j ACCEPT";

  systemd.services.nomad.after = [ "network-online.target" ];
}
