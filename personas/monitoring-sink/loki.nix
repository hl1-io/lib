{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ loki ];

  systemd.tmpfiles.rules = [ "d /opt/loki 0700 loki loki" ];

  networking.firewall.allowedTCPPorts = [ 3100 ];

  services.loki = {
    enable = true;
    configFile = ./loki.yaml;
  };

  hl1-io.backup.paths = [ "/opt/loki" ];
}
