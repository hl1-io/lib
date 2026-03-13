{ lib, ... }:
with lib; {
  options.hl1-io.vault = {
    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
    };
    port = mkOption {
      type = types.int;
      default = 4444;
    };
  };

  options.hl1-io.vault-agency = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        enable = mkOption {
          type = types.bool;
          description = "Enables a wrapped vault-agent";
          default = false;
        };
        name = mkOption {
          type = types.str;
          description = "Vault Agent Name";
          default = "unnamed-agent";
        };
        user = mkOption {
          type = types.str;
          description = "Vault Agent will run as this user";
          default = "root";
        };
        group = mkOption {
          type = types.str;
          description = "Vault Agent will run as this group";
          default = "root";
        };
        destination = mkOption {
          type = types.str;
          description = "Destination of the templated file";
        };
        template = mkOption {
          type = types.str;
          description = "Literal content of the template";
        };
        unit = mkOption {
          type = types.str;
          description = "SystemD unit to restart when values change";
          default = "";
        };
      };
    });
    default = { };
  };
}
