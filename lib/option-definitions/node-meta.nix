{ lib, ... }:
with lib; {
  options.hl1-io.node-meta = {
    expected-fqdn = mkOption {
      type = types.str;
      default = "node.example.com";
    };
    personas = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };
}
