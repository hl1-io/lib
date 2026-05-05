{ config, pkgs, lib, ... }:
let
  cfg = config.hl1-io.space-engineers;
  user = "spaceengineers";
  group = "spaceengineers";

  # Tails the newest log file from the game's Logs directory into journald.
  # Runs as a background child in the same cgroup; killed automatically when
  # the service stops via KillMode=control-group.
  logTailScript = pkgs.writeShellScript "se-log-tail" ''
    set -euo pipefail
    LOG_DIR="${cfg.installDir}/game/Logs"

    # Wait up to 30s for the log directory to be populated
    for i in $(${pkgs.coreutils}/bin/seq 30); do
      LOG=$(find "$LOG_DIR" -name "*.log" 2>/dev/null | sort | tail -1 || true)
      [ -n "$LOG" ] && break
      sleep 1
    done

    if [ -z "''${LOG:-}" ]; then
      echo "se-log-tail: no log file appeared in $LOG_DIR after 30s"
      exit 0
    fi

    echo "se-log-tail: tailing $LOG"
    exec tail -n0 -f "$LOG" | ${pkgs.util-linux}/bin/logger -t space-engineers-game
  '';

  serverScript = pkgs.writeShellScript "se-server" ''
    set -euo pipefail

    # Space Engineers initialises Xalia (a SDL-based windowing layer) even in
    # -console mode. xvfb-run provides a throwaway virtual X11 display so that
    # SDL/Xalia can find a video driver without a physical screen attached.
    ${pkgs.xvfb-run}/bin/xvfb-run --auto-servernum \
      ${pkgs.umu-launcher}/bin/umu-run \
        ${cfg.installDir}/game/SpaceEngineersDedicated.exe \
        -path ${cfg.installDir}/instance \
        -console \
        ${lib.concatStringsSep " " cfg.extraServerArgs} &
    SERVER_PID=$!

    # Start log forwarding in the background (same cgroup, auto-killed on stop)
    ${logTailScript} &

    wait $SERVER_PID
  '';
in
{
  systemd.services.space-engineers = {
    description = "Space Engineers Dedicated Server";
    wantedBy = [ "multi-user.target" ];
    requires = [ "space-engineers-install.service" ];
    after = [
      "space-engineers-install.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      WorkingDirectory = "${cfg.installDir}/game";
      Environment = [
        "HOME=${cfg.installDir}"
        "STEAM_COMPAT_DATA_PATH=${cfg.installDir}/proton-prefix"
        "STEAM_COMPAT_CLIENT_INSTALL_PATH=${cfg.installDir}"
        "GAMEID=umu-${toString cfg.steamAppId}"
        # Proton GE is downloaded by space-engineers-install.service into this path.
        # It must not reference a nix package — proton-ge-bin outputs a bare archive
        # file that buildEnv cannot merge into the system environment.
        "PROTONPATH=${cfg.installDir}/proton"
        # Set to 1 to capture verbose Proton/Wine diagnostics in the journal
        "PROTON_LOG=0"
      ];
      ExecStart = serverScript;
      Restart = "on-failure";
      RestartSec = "15s";
      # Kills server + log-tail child together on service stop
      KillMode = "control-group";
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "space-engineers";
    };
  };
}
