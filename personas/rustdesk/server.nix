{
  lib,
  nodes,
  ...
}:
{
  hl1-io.node-meta.personas = [ "rustdesk-server" ];
  services.rustdesk-server = {
    enable = true;
    openFirewall = true;
    signal = {
      enable = true;
      relayHosts = lib.attrNames (
        lib.filterAttrs (
          hostname: node: (lib.lists.elem "rustdesk-relay" node.config.hl1-io.node-meta.personas)
        ) nodes
      );
    };
  };
}
