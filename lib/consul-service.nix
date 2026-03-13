{ config, lib, ... }:
with lib;
let
  mkConsulService = serviceId: cfg:
    with cfg;
    mkIf enable {
      environment.etc."consul.d/${serviceId}.service.hcl" = {
        user = "consul";
        group = "consul";
        mode = "444";
        text = let
          tags = [ ] ++ optional
            (builtins.stringLength subdomain > 0 || routerType == "tcp")
            (if routerType == "http" then
              "traefik.http.routers.${serviceId}.rule=Host(`${subdomain}.${config.hl1-io.domains.primary}`)"
            else if routerType == "tcp-sni" then
              "traefik.tcp.routers.${serviceId}.rule=HostSNI(`${subdomain}.${config.hl1-io.domains.primary}`)"
            else
              "traefik.tcp.routers.${serviceId}.rule=HostSNI(`*`)")
            ++ optional (httpsBackend && routerType == "http")
            "traefik.http.services.${serviceId}.loadbalancer.server.scheme=https"
            ++ optional (builtins.stringLength entrypoint > 0)
            (if routerType == "http" then
              "traefik.http.routers.${serviceId}.entrypoints=${entrypoint}"
            else
              "traefik.tcp.routers.${serviceId}.entrypoints=${entrypoint}")
            ++ optional (routerType == "tcp-sni")
            "traefik.tcp.routers.${serviceId}.tls=true";
        in ''
          service {
            id = "${serviceId}"
            name = "${serviceId}"
            meta = {
              description = "${label}"
            }
            port = ${toString port}
            ${
              if (builtins.stringLength address > 0) then
                ''address = "${address}"''
              else
                ""
            }
            tags = [
              "traefik.enable=true",
              ${lib.concatMapStrings (tag: ''"${tag}",'' + "\n") tags}
            ]
          }
        '';
      };
    };
  consulServices = mapAttrsToList mkConsulService config.hl1-io.consul.services;
in {

  config.environment =
    mkMerge (map (watcher: watcher.content.environment) consulServices);

  config.assertions = builtins.concatMap (service: [{
    assertion = builtins.all
      (s: builtins.stringLength s > 0 && !(builtins.match ".*[ ].*" s != null))
      (builtins.attrNames service);
    message = "Consul service keys contain spaces: ${
        builtins.toString
        (builtins.filter (s: builtins.match ".*[ ].*" s != null)
          (builtins.attrNames service))
      }";
  }]) consulServices;
}
