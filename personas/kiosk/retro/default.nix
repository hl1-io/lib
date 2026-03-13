{ config, pkgs, ... }:
let session-name = "__retro-term-kiosk";
in {
  imports = [ ../base-kiosk.nix ];
  environment.systemPackages = with pkgs; [ cool-retro-term sqlite wander ];
  services.cage = {
    program =
      # "${pkgs.cool-retro-term}/bin/cool-retro-term --fullscreen -e fish";
      "${pkgs.cool-retro-term}/bin/cool-retro-term --fullscreen -e /etc/retro-kiosk.fish";
    # environment = { SKIP_WELCOME_SPLASH = "yes"; };
  };

  # systemd.services."cage-tty1".postStart = ''
  #   sleep 5
  #   mkdir -p /tmp/kiosk/.local/share/cool-retro-term
  #   db_file=$(fd .sqlite /tmp/kiosk/.local/share/cool-retro-term)

  #   cat /etc/retro-kiosk.sql | ${pkgs.sqlite}/bin/sqlite3 $db_file
  # '';

  environment.etc."retro-kiosk.fish" = {
    uid = 8000;
    mode = "755";
    text = ''
      #!/usr/bin/env fish
      set session_started (${pkgs.zellij}/bin/zellij list-sessions | grep "${session-name}" | wc -l)

      if [ "$session_started" = "1" ]
        ${pkgs.zellij}/bin/zellij kill-session "${session-name}";
        ${pkgs.zellij}/bin/zellij delete-session "${session-name}";
      end

      ${pkgs.zellij}/bin/zellij -d -l /etc/retro-kiosk.kdl -s ${session-name};
    '';
  };

  environment.etc."retro-kiosk.sql" = {
    uid = 8000;
    text = ''
      INSERT OR REPLACE INTO settings 
        SELECT '{
        "backgroundColor": "#000000",
        "fontColor": "#ff8100",
        "flickering": 0.1468,
        "horizontalSync": 0.2129,
        "staticNoise": 0.1198,
        "chromaColor": 0.6563,
        "saturationColor": 0.2483,
        "screenCurvature": 0,
        "glowingLine": 0.2,
        "burnIn": 0.8185,
        "bloom": 0.7593,
        "rasterization": 1,
        "jitter": 0.1997,
        "rbgShift": 0,
        "brightness": 0.5,
        "contrast": 0.7959,
        "ambientLight": 0.2,
        "windowOpacity": 1,
        "fontName": "TERMINUS_SCALED",
        "fontWidth": 0.85,
        "margin": 1,
        "blinkingCursor": false,
        "frameMargin": 0.1,
        "name": "custom",
        "version": 2
      }', '_CURRENT_PROFILE' as setting
      ;
    '';
  };

  environment.etc."retro-kiosk.kdl" = {
    uid = 8000;
    text = ''
      layout {
        tab {
          pane command="btop"
        }
        tab {
          pane command="fastfetch"
        }
        tab {
          pane {
            command "wander"
            args "-a" "https://nomad.${config.hl1-io.domains.primary}"
          }
        }
      }
      pane_frames false
    '';
  };

  systemd.timers."retro-kiosk-flipper" = {
    enable = true;
    timerConfig = {
      OnUnitActiveSec = "30s";
      OnBootSec = "30s";
      AccuracySec = "1ms";
    };
    wantedBy = [ "timers.target" ];
  };
  systemd.services."retro-kiosk-flipper" = {
    enable = true;
    environment = { ZELLIJ_SOCKET_DIR = "/var/run/user/8000/zellij"; };
    serviceConfig = {
      Type = "oneshot";
      User = "kiosk";
      ExecStart = ''
        ${pkgs.zellij}/bin/zellij -s "${session-name}" action go-to-next-tab'';
    };
  };
}
