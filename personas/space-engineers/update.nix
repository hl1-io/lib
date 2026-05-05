{ config, pkgs, ... }:
let
  cfg = config.hl1-io.space-engineers;
  appManifest = "${cfg.installDir}/game/steamapps/appmanifest_${toString cfg.steamAppId}.acf";

  updateScript = pkgs.writeShellScript "se-update" ''
    set -euo pipefail

    if [ ! -f "${appManifest}" ]; then
      echo "Game not yet installed (manifest missing). Skipping update."
      exit 0
    fi

    # Read the currently installed build ID
    INSTALLED=$(grep '"buildid"' "${appManifest}" | sed 's/.*"\([0-9]*\)".*/\1/')
    echo "Installed build: $INSTALLED"

    # Query the Steam Web API to check if an update is available.
    # ISteamApps/UpToDateCheck requires no API key and returns:
    #   { "response": { "up_to_date": bool, "required_version": int } }
    API=$(${pkgs.curl}/bin/curl -sf \
      "https://api.steampowered.com/ISteamApps/UpToDateCheck/v1/?appid=${toString cfg.steamAppId}&version=$INSTALLED")

    UP_TO_DATE=$(echo "$API" | ${pkgs.jq}/bin/jq -r '.response.up_to_date')

    if [ "$UP_TO_DATE" = "true" ]; then
      echo "No update available. Server untouched."
      exit 0
    fi

    LATEST=$(echo "$API" | ${pkgs.jq}/bin/jq -r '.response.required_version')
    echo "Update found: $INSTALLED -> $LATEST"

    echo "Stopping server..."
    systemctl stop space-engineers.service

    echo "Downloading update via SteamCMD..."
    HOME=${cfg.installDir} ${pkgs.steamcmd}/bin/steamcmd \
      +force_install_dir ${cfg.installDir}/game \
      +login anonymous \
      +app_update ${toString cfg.steamAppId} \
      +quit

    echo "Restarting server..."
    systemctl start space-engineers.service
  '';
in
{
  systemd.timers.space-engineers-update = {
    description = "Space Engineers: Daily update check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = cfg.updateCalendar;
      # Run a missed timer immediately on next boot
      Persistent = true;
      # Spread the update window by up to 5 minutes to avoid thundering herd
      RandomizedDelaySec = "300";
    };
  };

  systemd.services.space-engineers-update = {
    description = "Space Engineers: Update check and apply";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      # Must run as root to issue systemctl stop/start on other units
      User = "root";
      ExecStart = updateScript;
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "space-engineers-update";
    };
  };
}
