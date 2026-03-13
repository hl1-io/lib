{ lib, ... }:
with lib;
{
  options.hl1-io.domains = {
    primary = mkOption {
      type = types.str;
      description = "Domain that will contain more (or all) services and hosts for this cluster";
      default = "example.com";
    };
    additional = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Any additional domains that may contain services and hosts for this cluster";
    };
    authDomain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Domain to use for OAuth session cookies (will usually be domains.primary, in which case it is not needed)";
    };

    caUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Kanidm URL, use to override the default stepca.\${domains.primary}";
    };
  };
}
