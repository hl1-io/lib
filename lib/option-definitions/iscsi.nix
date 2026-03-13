{ lib, ... }:
with lib; 
let
  mountSpec = types.submodule {
    enable = mkOption { type = types.bool; default = false; };
    portal = mkOption { type = types.nullOr types.str; default = null; };
    target = mkOption { type = types.str; };
    mountPath = mkOption { type = types.str; };
    
  };
in
{
  options.hl1-io.iscsi = {
    mounts = types.attrsOf mountSpec;
    defaultPortal = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };
}
