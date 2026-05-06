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

    # umu-launcher (Proton) wraps the server in a pressure-vessel container
    # with its own /tmp namespace, which means xvfb-run's X11 socket at
    # /tmp/.X11-unix/XN is invisible to Wine inside the container.
    # Switching to plain Wine avoids the container entirely, so xvfb-run's
    # socket is directly reachable.
    #
    # Space Engineers initialises Xalia (SDL-based windowing) even in -console
    # mode. xvfb-run with a 24-bit screen provides the virtual display Xalia
    # needs without a physical monitor.
    ${pkgs.xvfb-run}/bin/xvfb-run \
      --auto-servernum \
      --server-args="-screen 0 1920x1080x24" \
      ${pkgs.wineWowPackages.stable}/bin/wine64 \
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
        "WINEPREFIX=${cfg.installDir}/wine-prefix"
        # Suppress noise; set to +all to capture verbose Wine diagnostics
        "WINEDEBUG=-all"
        # Prevent Wine from showing popup error dialogs (would block headlessly)
        "WINEDLLOVERRIDES=mscoree=n;mshtml="
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
