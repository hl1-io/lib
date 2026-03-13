{ pkgs, ... }:

{
  hl1-io.node-meta.personas = [ "kiosk" ];
  users.groups.kiosk = { };
  users.users.kiosk = {
    uid = 8000;
    group = "kiosk";
    name = "kiosk";
    createHome = true;
    home = "/tmp/kiosk";
    isNormalUser = true;
  };
  # These are required, and not defaults
  services.cage.enable = true;
  services.cage.user = "kiosk";
  systemd.services."cage-tty1".after =
    [ "network-online.target" "systemd-resolved.service" ];
  systemd.services."cage-tty1".wants =
    [ "network-online.target" "systemd-resolved.service" ];

  # Attempt to start cage by default
  systemd.services."getty@tty1".enable = false;
  systemd.services."cage-tty1".enable = true;
  systemd.services."cage-tty1".wantedBy = [ "multi-user.target" ];
}
