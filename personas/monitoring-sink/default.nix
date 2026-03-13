{ config, lib, ... }:

{
  hl1-io.node-meta.personas = [ "monitoring-sink" ];
  imports = [
    ./timescale.nix
    ./loki.nix
  ]
  ++ [ (lib.mkIf config.hl1-io.monitoring.sink.enableGrafana ./grafana.auto.nix).content ];
}
