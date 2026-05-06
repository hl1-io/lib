{ lib, ... }:
with lib;
{
  options.hl1-io.space-engineers = {
    installDir = mkOption {
      type = types.str;
      default = "/var/lib/space-engineers";
      description = "Root directory for all Space Engineers server data.";
    };

    steamAppId = mkOption {
      type = types.int;
      default = 298740;
      description = "Steam App ID for the Space Engineers dedicated server.";
    };

    gamePort = mkOption {
      type = types.port;
      default = 27016;
      description = "UDP port for Space Engineers game traffic.";
    };

    queryPort = mkOption {
      type = types.port;
      default = 27015;
      description = "UDP port for Steam query (server browser).";
    };

    updateCalendar = mkOption {
      type = types.str;
      default = "*-*-* 04:00:00";
      description = "systemd OnCalendar expression for the daily update check.";
    };

    extraServerArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments appended to SpaceEngineersDedicated.exe.";
      example = [ "-maxPlayers" "8" ];
    };
  };
}
