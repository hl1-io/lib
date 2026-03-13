{
  pkgs,
  config,
  nodes,
  ...
}:
with pkgs;
{
  config = {
    environment.systemPackages = lib.mkIf (config.hl1-io.master != "") (
      with pkgs;
      let
        master-fqdn = nodes."${config.hl1-io.master}".config.hl1-io.node-meta.expected-fqdn;
        receive-files = writeScriptBin "receive-files" (
          builtins.replaceStrings [ "@master@" ] [ "${master-fqdn}:8010" ] (
            builtins.readFile ./scripts/receive-files.fish
          )
        );
        send-file = writeScriptBin "send-file" (
          builtins.replaceStrings [ "@master@" ] [ "${master-fqdn}:8010" ] (
            builtins.readFile ./scripts/send-file.fish
          )
        );
      in
      [
        socat
        age
        send-file
        receive-files
      ]
    );
  };
}
