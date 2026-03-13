{ lib, ... }:
with lib; {
  options.hl1-io.systemd = {
    watch = mkOption {
      default = { };
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            description = "Restarts the given systemd unit when files change";
            default = false;
          };
          paths = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          unit = mkOption { type = types.str; };
        };
      });
    };
  };
}
