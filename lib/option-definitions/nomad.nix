{ lib, ... }:
with lib; {
  options.hl1-io.nomad = {
    acl-enabled = mkOption {
      type = types.bool;
      default = false;
    };
    pool = mkOption {
      type = types.string;
      default = "default";
    };
  };
}
