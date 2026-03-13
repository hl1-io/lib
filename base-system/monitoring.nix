{ config, lib, ... }:

let monitoringEnabled = config.hl1-io.monitoring.client.enable;
in {
  # Telegraf (Metrics, Logs?)
  users.users.promtail =
    lib.mkIf monitoringEnabled { extraGroups = [ "docker" ]; };
  systemd.tmpfiles.rules =
    lib.mkIf monitoringEnabled [ "d /opt/promtail 0700 promtail promtail" ];
  networking.firewall.allowedTCPPorts = lib.mkIf monitoringEnabled [ 8090 ];
  services.promtail = {
    enable = monitoringEnabled;
    configuration = {
      server = {
        http_listen_port = 8090;
        log_level = "debug";
      };
      clients = [{
        url =
          "http://loki.services.c.${config.hl1-io.domains.primary}:3100/loki/api/v1/push";
      }];
      positions = { filename = "/opt/promtail/positions.yaml"; };
      target_config = { sync_period = "10s"; };
      scrape_configs = [
        {
          job_name = "JournalD Logs";
          journal = {
            json = true;
            max_age = "12h";
            labels = {
              job = "journald";
              host = "${config.networking.hostName}";
            };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }
        {
          # This only works for docker that isn't running as rootless :(
          # We can't use wildcards here, which kinda blows
          job_name = "Docker Logs";
          docker_sd_configs = [{
            host = "unix:///var/run/docker.sock";
            refresh_interval = "5s";
          }];
          # relabel_configs = [{
          #   source_labels = [ "__meta_docker_container_name" ];
          #   regex = "/(.*)";
          #   target_label = "container";
          # }];
        }
      ];
    };
  };

  # services.telegraf = {
  #   enable = monitoringEnabled;
  #   outputs = {
  #   };
  # };
}
