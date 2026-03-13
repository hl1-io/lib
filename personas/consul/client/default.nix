{ config, lib, ... }:

{
  hl1-io.node-meta.personas = [ "consul-client" ];
  services.consul.enable = true;
  services.consul.forceAddrFamily = "ipv4";
  services.consul.webUi = true;

  networking.usePredictableInterfaceNames = lib.mkDefault true;

  environment.etc."consul.d/consul.client.hcl" = {
    user = "consul";
    group = "consul";
    mode = "444";
    text = ''
      datacenter = "${config.hl1-io.datacenter}"

      bind_addr = "{{ GetPrivateInterfaces | exclude \"network\" \"100.64.0.0/10\" | exclude \"network\" \"172.17.0.1/16\" | attr \"address\" }}"
      client_addr = "127.0.0.1"

      server           = false
      ports {
        dns  = 8600
        http = 8500
        grpc = 8502
      }

      connect {
        enabled = true
      }

      retry_join = [
        "${config.hl1-io.consul.server.host}"
      ]
      node_meta {
        managed = "colmena"
      }
    '';
  };

  # Wait for network to be online before starting
  # This just avoids predictable but useless service failures
  systemd.services.consul.after = [ "network-online.target" ];
  systemd.services.consul.wants = [ "network-online.target" ];

  services.consul.extraConfigFiles = [ "/etc/consul.d/consul.client.hcl" ];
  networking.firewall.allowedTCPPorts = [
    # https://developer.hashicorp.com/consul/docs/install/ports#consul-servers
    8500
    8501 # HTTP
    8502
    8503 # GRPC
    8600 # DNS
    8300
    8301
    8302 # SERF
  ];

  # Of note for later
  # https://mynixos.com/nixpkgs/options/services.consul-template
}
