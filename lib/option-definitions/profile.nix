{ lib, ... }:
with lib;
{
  options.hl1-io.profile = {
    givenName = mkOption {
      type = types.str;
      default = "";
    };
    familyName = mkOption {
      type = types.str;
      default = "";
    };
    username = mkOption {
      type = types.str;
      default = "hl1-user";
    };
    email = mkOption {
      type = types.str;
      default = "user@example.com";
      example = "user@example.com";
    };
  };
}
