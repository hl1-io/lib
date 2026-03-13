{ config, ... }:

{
  hl1-io.node-meta.personas = [ "consul-server" ];
  services.consul.enable = true;
  services.consul.webUi = true;
  services.consul.forceAddrFamily = "ipv4";

  hl1-io.consul.services."consul-ui" = {
    enable = true;
    label = "Consul UI";
    port = 8500;
    subdomain = "consul";
    address = "127.0.0.1";
  };

  environment.etc."consul.d/consul.server.hcl" = {
    user = "consul";
    group = "consul";
    mode = "444";
    text = ''
      datacenter = "${config.hl1-io.datacenter}"

      # Escapes here make it gross but are needed
      bind_addr = "{{ GetPrivateInterfaces | exclude \"network\" \"100.64.0.0/10\" | exclude \"network\" \"172.17.0.1/16\" | attr \"address\" }}"

      client_addr = "127.0.0.1 {{ GetPrivateIPs }}"

      server           = true
      bootstrap        = true
      bootstrap_expect = 1

      ports {
        dns  = 53
        http = 8500
        grpc = 8502
      }

      domain = "c.${config.hl1-io.domains.primary}"

      connect {
        enabled = true
      }

      node_meta {
        managed = "colmena"
      }
    '';
  };

  systemd.services.consul.serviceConfig = {
    AmbientCapabilities = "CAP_NET_BIND_SERVICE";
  };
  systemd.services.consul.after = [ "network-online.target" ];
  systemd.services.consul.wants = [ "network-online.target" ];

  services.consul.extraConfigFiles = [ "/etc/consul.d/consul.server.hcl" ];

  networking.firewall.allowedTCPPorts = [
    # https://developer.hashicorp.com/consul/docs/install/ports#consul-servers
    8500
    8501 # HTTP
    8502
    8503 # GRPC
    53 # DNS
    8300
    8301
    8302 # SERF
  ];

  hl1-io.backup.paths = [ "/var/lib/consul" ];
}
