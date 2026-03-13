{ pkgs, ... }:

{
  hl1-io.node-meta.personas = [ "bastion" ];
  environment.systemPackages = with pkgs; [ sshportal ];

  users.users.sshportal = {
    isSystemUser = true;
    group = "sshportal";
  };
  users.groups.sshportal = { };

  systemd.tmpfiles.rules = [ "d /etc/sshportal 0700 sshportal sshportal" ];

  systemd.services.sshportal = {
    name = "sshportal.service";
    description = "Transparent SSH Bastion";
    enable = true;
    serviceConfig = {
      User = "sshportal";
      WorkingDirectory = "/etc/sshportal";
      ExecStart = "${pkgs.sshportal}/bin/sshportal server";
      Restart = "always";
    };
    wantedBy = [ "multi-user.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 2222 ];
}

