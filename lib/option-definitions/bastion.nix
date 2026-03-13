{ lib, ... }:
with lib; {
  options.hl1-io.bastion = {
    port = mkOption {
      type = types.int;
      default = 2222;
    };
  };
}
