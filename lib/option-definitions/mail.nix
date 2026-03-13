{ lib, config, ... }:
with lib; {
  options.hl1-io.mail = {
    additionalDomains = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    fqdn = mkOption {
      type = types.str;
      default = "mail." + config.hl1-io.domains.primary;
    };
    account = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          passwordCommand = mkOption { type = types.listOf types.str; };
          domain = mkOption {
            type = types.str;
            default = config.hl1-io.domains.primary;
          };
          serviceAccount = mkOption {
            type = types.bool;
            default = false;
          };
        };
      });
      default = { };
    };
  };
}
