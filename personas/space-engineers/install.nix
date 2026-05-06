{ config, pkgs, ... }:
let
  cfg = config.hl1-io.space-engineers;
  user = "spaceengineers";
  group = "spaceengineers";
  appManifest = "${cfg.installDir}/game/steamapps/appmanifest_${toString cfg.steamAppId}.acf";

  installScript = pkgs.writeShellScript "se-install" ''
    set -euo pipefail

    echo "Installing Space Engineers (App ID ${toString cfg.steamAppId}) via SteamCMD..."
    ${pkgs.steamcmd}/bin/steamcmd \
      +force_install_dir ${cfg.installDir}/game \
      +login anonymous \
      +app_update ${toString cfg.steamAppId} validate \
      +quit

    # Initialise the Wine prefix. wineboot needs a display even for headless
    # prefix creation, so run it under a throwaway Xvfb instance.
    echo "Initialising Wine prefix..."
    WINEPREFIX="${cfg.installDir}/wine-prefix" \
    WINEDEBUG=-all \
      ${pkgs.xvfb-run}/bin/xvfb-run \
        --auto-servernum \
        --server-args="-screen 0 1920x1080x24" \
        ${pkgs.wineWowPackages.stable}/bin/wineboot --init

    echo "Installation complete."
  '';
in
{
  systemd.services.space-engineers-install = {
    description = "Space Engineers: First-run installation via SteamCMD";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "systemd-tmpfiles-setup.service"
    ];
    wants = [ "network-online.target" ];
    # Skip if already installed
    unitConfig.ConditionPathExists = "!${appManifest}";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
      Group = group;
      Environment = "HOME=${cfg.installDir}";
      ExecStart = installScript;
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "space-engineers-install";
    };
  };
}
