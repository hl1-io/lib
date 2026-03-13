{ lib, ... }:
with lib;
let
  backupScript = types.submodule {
    options = {
      script = mkOption {
        type = types.path;
        description = "Relative path to the script file";
      };
      outpath = mkOption {
        type = types.str;
        description =
          "Path (relative to the backup root) of where the script result should go";
      };
    };
  };
in {
  options.hl1-io.backup = {
    nfs = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    paths = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    scripts = mkOption {
      type = types.listOf backupScript;
      default = [ ];
    };

    dailyRetention = mkOption {
      type = types.int;
      default = 365;
      description = "Number of daily backups to keep";
    };
  };
}
