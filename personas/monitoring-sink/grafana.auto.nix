{ config, ... }:

{
  hl1-io.vault-agency.grafana = {
    enable = false;
    user = "grafana";
    group = "grafana";
    destination = "/etc/grafana.env";
    template = ''
      {{ with secret kv/oauth/grafana }}
        GRAFANA_OAUTH_CLIENT_ID={{ .Data.client_id }}
        GRAFANA_OAUTH_CLIENT_SECRET={{ .Data.client_secret }}
      {{ end }}
    '';
    unit = "grafana.service";
  };

  hl1-io.consul.services."grafana" = {
    enable = true;
    label = "grafana";
    port = 4567;
    subdomain = "grafana";
  };

  networking.firewall.allowedTCPPorts = [ 4567 ];

  systemd.tmpfiles.rules = [ "d /etc/grafana/dashboards.d 0444 grafana grafana" ];

  # The idea here is to use vault-agent to render some file
  #   that will be used to configure grafana's OAuth Client ID
  #   and Secret ID
  # A requirement is that Grafana is restarted whenever this value
  #   changes.
  #
  # Setting it up this way means that we can generate the OAuth creds
  #   after the server is provisioned - without running into a chicken
  #   and egg scenario
  #
  # It may be benefitial to make some sort of bootstrap script that is
  #  added to the path of the server to accept a vault token, create the
  #  approle + role id & role secret, along with creating the kanidm id/secret
  #
  # If this is set up to work properly, it would be extremely benefitial
  #   to find a way to modularize it / make it into a function. A flake
  #   might be a good way to do this because it can have many inputs / outputs
  #   but that remains to be seen.
  # -- Could this be done with some sort of import ./modules { inherit val; } ?
  #
  #
  #
  systemd.services.grafana.serviceConfig = {
    EnvironmentFile = "/etc/grafana.env";
  };

  services.grafana = {
    enable = true;
    settings = {
      analytics = {
        reporting_enabled = false;
      };

      server = {
        http_addr = "0.0.0.0";
        http_port = 4567;
        domain = "grafana.${config.hl1-io.domains.primary}";
        root_url = "https://grafana.${config.hl1-io.domains.primary}";
      };
      users = {
        allow_org_create = false;
        allow_sign_up = false;
      };

      security = {
        # Handled via central auth
        disable_initial_admin_creation = true;
      };

      # Experimental
      "auth.generic_oauth" = {
        client_id = ""; # Externally Managed
        client_secret = ""; # Externally Managed
        auth_url = "";
        api_url = "";
        enabled = true;
        name = "HL Auth";
        allow_assign_grafana_admin = true;
        scopes = "email openid profile groups";
        use_refresh_token = true;
        login_attribute_path = "preferred_username";
        groups_attribute_path = "groups";
        role_attribute_path = "contains(grafana_role[*], 'GrafanaAdmin') && 'GrafanaAdmin' || contains(grafana_role[*], 'Admin') && 'Admin' || contains(grafana_role[*], 'Editor') && 'Editor' || 'Viewer'";
        allow_sign_up = true;
      };
    };

    provision = {
      dashboards = {
        path = ./grafana-dashboards;
      };
      datasources = {
        settings = {
          datasources = [
            {
              name = "loki";
              type = "loki";
              url = "http://loki.services.c.${config.hl1-io.domains.primary}:3100";
              settings = {
                editable = false;
              };
            }
          ];
        };
      };
    };
  };
}
