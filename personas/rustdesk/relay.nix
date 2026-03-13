{ ... }:
{
  hl1-io.node-meta.personas = [ "rustdesk-relay" ];
  services.rustdesk-server = {
    enable = true;
    openFirewall = true;
    signal = {
      enable = false;
    };
    relay = {
      enable = true;
    };
  };
}
