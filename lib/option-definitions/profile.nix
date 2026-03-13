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
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "SSH public keys that are authorized to log in as the default user";
      example = [ "ssh-ed25519 AAAA... user@host" ];
    };
  };
}
