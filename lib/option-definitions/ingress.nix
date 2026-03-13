{ lib, nodes, ... }:
with lib;
let
  entrypoint = types.submodule {
    options = {
      port = mkOption { type = types.int; };
      public = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
in
{
  options.hl1-io.ingress = {
    requestedEntrypoints = mkOption {
      type = types.attrsOf entrypoint;
      default = { };
      example = {
        postgres = {
          port = 5432;
          public = false;
        };
      };
      description = ''
        Used to create additional entrypoints on the ingress node (useful for things like postgres)
      '';
    };
  };
  config.assertions =
    let
      allEntrypoints = flatten (
        mapAttrsToList (
          nodeName: nodeConfig:
          mapAttrsToList (name: value: { inherit name value nodeName; }) (
            nodeConfig.config.hl1-io.ingress.requestedEntrypoints or { }
          )
        ) nodes
      );
      groupedEntrypoints = groupBy (e: e.name) allEntrypoints;
      duplicates = filter (entries: length entries > 1) (attrValues groupedEntrypoints);
      duplicateNames = concatStringsSep ", " (
        map (entries: "${head entries.name} (${concatStringsSep ", " (map (e: e.nodeName) entries)})") (
          filter (entries: length entries > 1) (attrValues groupedEntrypoints)
        )
      );
    in
    [
      {
        assertion = duplicates == [ ];
        message = "The following entrypoints are specified multiple times: ${duplicateNames}";
      }
    ];
}
