{ config, pkgs, lib, ... }:
with builtins;
let
  paths = config.hl1-io.backup.paths;
  backup-path-formatted = map (path: "backup	${path}	./") paths;
  backup-path-str = concatStringsSep "\n" backup-path-formatted;

  backup-script-packages = map (scriptConfig:
    pkgs.writeScriptBin (baseNameOf scriptConfig.outpath)
    (readFile scriptConfig.script)) config.hl1-io.backup.scripts;

  backup-script-lines = map (scriptConfig:
    "backup_script	${
      pkgs.writeScriptBin (baseNameOf scriptConfig.outpath)
      (readFile scriptConfig.script)
    }/bin/${baseNameOf scriptConfig.outpath}	_scripts/${scriptConfig.outpath}")
    config.hl1-io.backup.scripts;
  backup-script-str = concatStringsSep "\n" backup-script-lines;

  # rSnapshot Items:

  # Define the intervals and their corresponding settings
  rsnapshotIntervals = {
    daily = {
      onCalendar = "*-*-* 01:00:00"; # Run at 2 AM
      randomizedDelaySec = "4h"; # Add up to 4 hours of random delay
    };
  };

  # Function to create a timer and its corresponding service
  mkRsnapshotTimer = name: cfg: {
    "rsnapshot-${name}" = {
      description = "Timer for rsnapshot ${name} backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        RandomizedDelaySec = cfg.randomizedDelaySec;
        Persistent = true; # Run immediately if last run was missed
      };
    };
  };

  # Function to create the corresponding service
  mkRsnapshotService = name: cfg: {
    "rsnapshot-${name}" = {
      description = "Service for rsnapshot ${name} backup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.rsnapshot}/bin/rsnapshot ${name}";
      };
    };
  };

in {
  systemd.tmpfiles.rules = [ "d /opt/rsnapshot 0744 root root" ];

  fileSystems."/opt/rsnapshot" = lib.mkIf (config.hl1-io.backup.nfs != null) {
    device = "${config.hl1-io.backup.nfs}";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };

  # Write all backups scripts
  environment.systemPackages = backup-script-packages;

  services.rsnapshot = {
    enable = true;
    enableManualRsnapshot = true;
    # cronIntervals = {
    #   # 4:33 am / day
    #   daily = "33 4 * * *";
    #   # xx:05 / hour
    #   hourly = "5 * * * *";
    # };
    extraConfig = ''
      exclude	node_modules
      exclude	.bun
      exclude	.rustup
      exclude	.npm
      exclude	.pnpm-store
      exclude	.cargo
      exclude	.codeium
      exclude	.cache
      exclude	.go
      exclude	.vagrant.d
      exclude	.vscode-server
      
      exclude	.cargo
      exclude	cache
      exclude	.gradle
      exclude	.vscode
      
      # TODO: is this too broad?
      exclude	env
      exclude	site-packages
      exclude	.local/share/docker
      exclude	.local/share/Steam
      exclude	.local/share/pnpm

      exclude	.gnupg

      retain	daily	${builtins.toString config.hl1-io.backup.dailyRetention}

      snapshot_root	/opt/rsnapshot/${config.hl1-io.cluster-label}/${config.networking.hostName}
      verbose	3
      ${backup-path-str}
      ${backup-script-str}
      		'';
  };

  # Create all timers using mapAttrs
  systemd.timers =
    lib.mkMerge (lib.mapAttrsToList mkRsnapshotTimer rsnapshotIntervals);

  # Create all services using mapAttrs
  systemd.services =
    lib.mkMerge (lib.mapAttrsToList mkRsnapshotService rsnapshotIntervals);
}
