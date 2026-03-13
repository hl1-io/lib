{ lib, ... }:
with lib; {
  options.hl1-io._tmpl = {
    myOpt = mkOption {
      type = types.bool;
      description = "Describe me please!";

    };
  };
}
