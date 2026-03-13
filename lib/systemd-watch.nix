{ config, lib, ... }:
with lib;
let
  mkWatch = name: cfg:
    with cfg;
    mkIf enable {
      assertions = [
        {
          assertion = builtins.stringLength name > 0;
          message = "Name must not be empty";
        }
        {
          assertion = builtins.stringLength unit > 0;
          message = "Unit must not be empty";
        }
      ];

      systemd.services."hl1-io-${name}-watcher" = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "systemctl restart ${unit}";
          User = "root";
          Group = "root";
        };
      };
      # When role or secret are updated, restart the agent
      systemd.paths."hl1-io-${name}-watcher" = {
        wantedBy = [ "multi-user.target" ];
        pathConfig = { PathChanged = paths; };
      };
    };

  watches = mapAttrsToList mkWatch config.hl1-io.systemd.watch;
in {
  config.systemd = mkMerge (map (watcher: watcher.content.systemd) watches);
}
