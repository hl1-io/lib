{ config, ... }:

{
  networking.firewall.allowedTCPPorts = [ 4567 ];
  hl1-io.consul.services."grafana" = {
    enable = true;
    label = "grafana";
    port = 4567;
    subdomain = "grafana";
  };

  systemd.tmpfiles.rules =
    [ "d /etc/grafana/dashboards.d 0444 grafana grafana" ];

  services.grafana = {
    enable = true;
    settings = {
      analytics = { reporting_enabled = false; };

      server = {
        http_addr = "0.0.0.0";
        http_port = 4567;
      };
    };

    provision = {
      dashboards = { path = ./grafana-dashboards; };
      datasources = {
        settings = {
          datasources = [{
            name = "loki";
            type = "loki";
            url =
              "http://loki.services.c.${config.hl1-io.domains.primary}:3100";
            settings = { editable = false; };
          }];
        };
      };
    };
  };
}
