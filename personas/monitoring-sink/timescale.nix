{
  lib,
  config,
  pkgs,
  ...
}:
{
  hl1-io.backup.scripts = [
    {
      script = ./timescale-backup.sh;
      outpath = "timescaledb-monitoring";
    }
  ];

  networking.firewall.allowedTCPPorts = [ config.hl1-io.monitoring.sink.port ];

  environment.systemPackages = with pkgs; [ postgresql16Packages.timescaledb ];

  systemd.tmpfiles.rules = [ "d /var/lib/postgresql/monitoring-sink 0700 postgres postgres" ];

  services.postgresql = {
    enable = true;
    enableJIT = true;
    package = pkgs.postgresql_16_jit;
    # See https://github.com/NixOS/nixpkgs/issues/341408
    extraPlugins = [ pkgs.postgresql16JitPackages.timescaledb ];
    enableTCPIP = true;

    settings = {
      port = config.hl1-io.monitoring.sink.port;
      shared_preload_libraries = "timescaledb";
    };

    dataDir = "/var/lib/postgresql/monitoring-sink";

    authentication = ''
      local   all     all                        peer  map=root_as_others
      local   all     postgres                   peer
      host    all     all        0.0.0.0/0       md5
    '';

    identMap = ''
      root_as_others root     postgres
      root_as_others postgres postgres
      root_as_others pgadmin  postgres
    '';
  };

  hl1-io.consul.services."timescaledb" = {
    enable = true;
    label = "TimescaleDB";
    port = config.hl1-io.monitoring.sink.port;
    routerType = "tcp-sni";
    subdomain = "ts";
    entrypoint = "dbs";
    tls = true;
  };

  deployment.keys.pga = {
    text = "password123";
    permissions = "444";
  };

  # https://www.pgadmin.org/docs/pgadmin4/development/oauth2.html
  services.pgadmin = lib.mkIf config.hl1-io.monitoring.pgadmin.enable {
    enable = true;
    initialEmail = config.hl1-io.profile.email;
    openFirewall = true;
    initialPasswordFile = "/run/keys/pga";
    port = 9098;
    settings = { };
  };

  hl1-io.consul.services."pgadmin-timescale" = {
    enable = true;
    label = "TimescaleDB (UI)";
    port = 9098;
    subdomain = "pga";
  };
}
