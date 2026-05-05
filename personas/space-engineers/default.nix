{ config, pkgs, lib, ... }:
let
  cfg = config.hl1-io.space-engineers;
  user = "spaceengineers";
  group = "spaceengineers";
in
{
  imports = [
    ./install.nix
    ./server.nix
    ./update.nix
  ];

  hl1-io.node-meta.personas = [ "space-engineers" ];

  users.groups.${group} = { };
  users.users.${user} = {
    isSystemUser = true;
    group = group;
    home = cfg.installDir;
    createHome = false;
    description = "Space Engineers dedicated server user";
  };

  systemd.tmpfiles.rules = [
    "d ${cfg.installDir}                   0750 ${user} ${group} -"
    "d ${cfg.installDir}/game              0750 ${user} ${group} -"
    "d ${cfg.installDir}/proton            0750 ${user} ${group} -"
    "d ${cfg.installDir}/proton-prefix     0750 ${user} ${group} -"
    "d ${cfg.installDir}/instance          0750 ${user} ${group} -"
  ];

  environment.systemPackages = with pkgs; [
    steamcmd
    umu-launcher
  ];

  networking.firewall.allowedUDPPorts = [
    cfg.gamePort
    cfg.queryPort
  ];
}
