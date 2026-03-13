{ config, lib, ... }:
with lib;
let
  # cfg is currently the options defined in hl1-io.nix under vault-agent
  mkAgent = name: cfg:
    with cfg;
    mkIf enable {
      assertions = [
        {
          assertion = builtins.stringLength name > 0;
          message = "Name must not be empty";
        }
        {
          assertion = builtins.stringLength user > 0;
          message = "User must not be empty";
        }
      ];

      systemd.tmpfiles.rules = [
        "f /etc/vault-agency/${name}.role 0400 ${user} ${group}"
        "f /etc/vault-agency/${name}.secret 0400 ${user} ${group}"
      ];

      services.vault-agent.instances."managed-${name}" = {
        enable = cfg.enable;
        user = cfg.user;
        group = cfg.group;
        settings = {
          vault.address = "https://vault.${hl1-io.domains.primary}";
          auto_auth = [{
            method = [{
              type = "approle";
              config = {
                role_id_file_path = "/etc/vault-agency/${name}.role";
                secret_id_file_path = "/etc/vault-agency/${name}.secret";
                remove_secret_id_file_after_reading = false;
              };
            }];
          }];

          template = [{
            destination = destination;
            contents = template;
            exec =
              mkIf (unit != "") { command = [ "systemctl" "restart" unit ]; };
          }];
        };
      };

      hl1-io.systemd.watch."vault-agent-${name}" = {
        enable = true;
        paths = [
          "/etc/vault-agency/${name}.role"
          "/etc/vault-agency/${name}.secret"
        ];
        unit = "vault-agent-managed-${name}.service";
      };
    };

  agents = mapAttrsToList mkAgent config.hl1-io.vault-agency;
in {
  config.systemd = mkMerge (map (agent: agent.content.systemd) agents);
  config.services = mkMerge (map (agent: agent.content.services) agents);

  # # This needs to be specific to avoid recursion on the vault-agency key
  config.hl1-io.systemd.watch =
    mkMerge (map (agent: agent.content.hl1-io.systemd.watch) agents);
}
