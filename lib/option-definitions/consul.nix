{ lib, ... }:
with lib; {
  options.hl1-io.consul = {
    server = {
      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
      };
    };
    acl-enabled = mkOption {
      type = types.bool;
      default = false;
    };

    services = mkOption {
      default = { };
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            description = "";
            default = false;
          };
          label = mkOption {
            type = types.str;
            description =
              "Effectively the ID of the service. Identically labelled services will be load balanced";
          };
          port = mkOption { type = types.int; };
          subdomain = mkOption {
            type = types.str;
            default = "";
          };
          httpsBackend = mkOption {
            type = types.bool;
            default = false;
            description =
              "Flags if the service itself is serving https (e.g. kanidm)";
          };
          routerType = mkOption {
            type = types.enum [ "http" "tcp-sni" "tcp" ];
            default = "http";
            description = ''
              http -> web service
              tcp-sni -> TCP with TLS that can use SNI for routing (e.g. postgres)
              tcp -> TCP with or without TLS that cannot use SNI for routing (e.g. gitea ssh)
            '';
          };
          address = mkOption {
            type = types.str;
            default = "";
          };
          entrypoint = mkOption {
            type = types.str;
            default = "https";
          };
          tls = mkOption {
            type = types.bool;
            default = false;
            description =
              "Applies only to TCP Services; all HTTP services are tls enabled";
          };
        };
      });
    };

  };
}
