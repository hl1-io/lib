{ config, pkgs, ... }:
let
  cfg = config.hl1-io.space-engineers;
  user = "spaceengineers";
  group = "spaceengineers";
in
{
  systemd.services.space-engineers-display = {
    description = "Space Engineers: Virtual X display (Xvfb)";
    wantedBy = [ "multi-user.target" ];
    before = [ "space-engineers.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "2s";
      User = user;
      Group = group;
      # -ac disables X access control entirely so that Wine running inside
      # pressure-vessel's bwrap container can connect without needing an
      # Xauthority file (which xvfb-run would create on the host but the
      # container process cannot read).
      ExecStart = "${pkgs.xorg.xorgserver}/bin/Xvfb :99 -screen 0 1920x1080x24 -ac -nolisten tcp";
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "space-engineers-display";
    };
  };
}
