{ lib, ... }:
with lib;
{
  options.hl1-io.monitoring = {
    sink = {
      enableGrafana = mkOption {
        type = types.bool;
        default = true;
      };
      port = mkOption {
        type = types.int;
        default = 6543;
      };
      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
      };

      pgadmin = {
        enable = mkOption {
          type = types.bool;
          default = false;
        };
      };
    };
    client = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };
}
